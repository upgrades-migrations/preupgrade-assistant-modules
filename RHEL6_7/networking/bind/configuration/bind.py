#!/usr/bin/env python
#
# Simplified parsing of bind configuration, with include support and nested sections.

import re
import os.path

class ConfigParseError(Exception):
    """ Generic error when parsing config file """

    def __init__(self, message, error = None):
        super(self.__class__, self).__init__(message)
        self.error = error
    pass

class ConfigFile(object):
    """ Representation of single configuration file and its contents """
    def __init__(self, path):
        self.path = path
        self.load(path)
        self.status = None

    def __str__(self):
        return self.buffer

    def __repr__(self):
        return 'ConfigFile {0} ({1})'.format(
                self.path, self.buffer)

    def load(self, path):
        with open(path, 'r') as f:
            self.buffer = self.original = f.read()
            f.close()

    def is_modified(self):
        return (self.origina == self.buff)

class ConfigSection(object):
    """ Representation of section or key inside single configuration file """
    def __init__(self, config, name=None, start=None, end=None):
        self.config = config
        self.name = name
        self.start = start
        self.end = end

    def value(self):
        return self.config.buffer[self.start:self.end+1]

def log_info(msg):
    print(msg)

def log_debug(msg):
    log_info(msg)
    pass

# Main parser class
class BindParser(object):
    """ Parser file with support of included files.

    Reads ISC BIND configuration file and tries to skip commented blocks, nested sections and similar stuff.
    """

    CONFIG_FILE = "/etc/named.conf"
    FILES_TO_CHECK = []

    ###########################################################
    ### function for parsing of config files
    ###########################################################
    def is_comment_start(self, istr, index=0):
        if istr[index] == "#" or (
                index+1 < len(istr) and istr[index:index+2] in ["//", "/*"]):
            return True
        return False

    def find_end_of_comment(self, istr, index=0):
        """
        Returns index where the comment ends.

        :param istr: input string
        :param index: begin search from the index; from the start by default

        Support usual comments till the end of line (//, #) and block comment
        like (/* comment */). In case that index is outside of the string or end
        of the comment is not found, return -1.

        In case of block comment, returned index is position of slash after star.
        """
        length = len(istr)

        if index >= length or index < 0:
            return -1

        if istr[index] == "#" or istr[index:].startswith("//"):
            return istr.find("\n", index)

        if index+2 < length and istr[index:index+2] == "/*":
            res = istr.find("*/", index+2)
            if res != -1:
                return res + 1

        return -1

    def is_opening_char(self, c):
         return c in "\"'{(["

    def remove_comments(self, istr):
        """
        Removes all comments from the given string.

        :param istr: input string
        :return: return
        """

        isCommented = False
        isBlockComment = False
        str_open = "\""
        ostr = ""

        length = len(istr)
        index = 0

        while index < length:
            if self.is_comment_start(istr, index):
                index = self.find_end_of_comment(istr,index)
                if index == -1:
                    # comment till EOF
                    break
                if istr[index] == "\n":
                    ostr += "\n"
            elif istr[index] in str_open:
                end_str = self.find_closing_char(istr, index)
                if end_str == -1:
                    ostr += istr[index:]
                    break
                ostr += istr[index:end_str+1]
                index = end_str
            else:
                ostr += istr[index]
            index += 1

        return ostr

    def find_next_token(self, istr,index=0, end_index=-1):
        """
        Return index of another interesting token or -1 when there is not next.

        :param istr: input string
        :param index: begin search from the index; from the start by default
        :param end_index: stop searching at the end_index or end of the string

        In case that initial index contains already some token, skip to another.
        But when searching starts on whitespace or beginning of the comment,
        choose the first one.

        The function would be confusing in case of brackets, but content between
        brackets is not evaulated as new tokens.
        E.g.:

        "find { me };"      : 5
        " me"               : 1
        "find /* me */ me " : 13
        "/* me */ me"       : 9
        "me;"               : 2
        "{ me }; me"        : 6
        "{ me }  me"        : 8
        "me }  me"          : 3
        "}} me"             : 1
        "me"                : -1
        "{ me } "           : -1
        """
        length = len(istr)
        if length < end_index or end_index < 0:
            end_index = length

        if index >= end_index or index < 0:
            return -1

        #skip to the end of the current token
        if istr[index] == '\\':
            index += 2
            if index > length:
                return -1
        elif self.is_opening_char(istr[index]):
            index2 = self.find_closing_char(istr, index)
            if index2 == -1:
                return -1
            index = index2 +1;
        elif self.is_comment_start(istr, index):
            index2 = self.find_end_of_comment(istr, index)
            if index2 == -1:
                return -1
            index = index2 +1
        elif istr[index] not in "\n\t ;})]":
            # so we have to skip to the end of the current token
            index += 1
            while index < end_index:
                if (istr[index] in "\n\t ;})]"
                        or self.is_comment_start(istr, index)
                        or self.is_opening_char(istr[index])):
                    break
                index += 1
        elif istr[index] in ";)]}":
            index += 1

        # find next token (can be already under the current index)
        while index < end_index:
            if istr[index] == '\\':
                index += 2
                continue
            elif self.is_comment_start(istr, index):
                index = self.find_end_of_comment(istr, index)
                if index == -1:
                    break
            elif self.is_opening_char(istr[index]) or istr[index] not in "\t\n ":
                return index
            index += 1
        return -1


    def find_closing_char(self, istr, index=0):
        """
        Returns index of equivalent closing character.

        :param istr: input string

        It's similar to the "find" method that returns index of the first character
        of the searched character or -1. But in this function the corresponding
        closing character is looked up, ignoring characters inside strings
        and comments. E.g. for
            "(hello (world) /* ) */ ), he would say"
        index of the third ")" is returned.
        """
        important_chars = { #TODO: should be that rather global var?
            "{" : "}",
            "(" : ")",
            "[" : "]",
            "\"" : "\"",
            ";" : None,
            }
        length = len(istr)

        if length < 2:
            return -1

        if index >= length or index < 0:
            return -1

        closing_char = important_chars.get(istr[index], ';')
        if closing_char is None:
            return -1;

        isString = istr[index] in "\""
        index += 1
        curr_c = ""
        while index < length:
            curr_c = istr[index]
            if curr_c == '//':
                index += 2
            elif self.is_comment_start(istr, index) and not isString:
                index = self.find_end_of_comment(istr, index)
                if index == -1:
                    return -1
            elif not isString and self.is_opening_char(curr_c):
                deep_close = self.find_closing_char(istr[index:])
                if deep_close == -1:
                    break
                index += deep_close
            elif curr_c == closing_char:
                if curr_c == ';':
                    index -= 1
                return index
            index += 1

        return -1

    def find_key(self, istr, key, index=0, end_index=-1, only_first=True):
        """
        Return index of the key or -1.

        :param istr: input string; it could be whole file or content of a section
        :param key: name of the searched key in the current scope
        :param index: start searching from the index
        :param end_index: stop searching at the end_index or end of the string

        Funtion is not recursive. Searched key has to be in the current scope.
        Attention:

        In case that input string contains data outside of section by mistake,
        the closing character is ignored and the key outside of scope could be
        found. Example of such wrong input could be:
              key1 "val"
              key2 { key-ignored "val-ignored" };
            };
            controls { ... };
        In this case, the key "controls" is outside of original scope. But for this
        cases you can set end_index to value, where searching should end. In case
        you set end_index higher then length of the string, end_index will be
        automatically corrected to the end of the input string.
        """
        length = len(istr)
        keylen = len(key)

        if length < end_index or end_index < 0:
            end_index = length

        if index >= end_index or index < 0:
            return -1

        while index != -1:
            remains = istr[index:]
            if istr.startswith(key, index):
                if index+keylen < end_index and istr[index+keylen] in "\n\t {;":
                    # key has been found
                    return index

            while not only_first and index != -1 and istr[index] != ";":
                index = self.find_next_token(istr, index)
            index = self.find_next_token(istr, index)

        return -1

    def find_val_bounds_of_key(self, config, key, index=0, end_index=-1):
        """
        Return indexes of beginning and end of the value of the key.

        Otherwise return pair -1, -1.
        """
        index = self.find_next_token(config, self.find_key(config, key, index, end_index))
        close_index = self.find_closing_char(config, index)
        if close_index == -1 or (close_index > end_index and end_index > 0):
            return -1, -1
        return index, close_index

    def find_next_val(self, cfg, key=None, index=0, end_index=-1):
        """ Find following token
            :param cfg: ConfigFile
            returns ConfigSection object or None
        """
        start = self.find_next_token(cfg.buffer, index)
        end = self.find_closing_char(cfg.buffer, start)
        if end == -1 or (end > end_index and end_index > 0):
            return None
        else:
            return ConfigSection(cfg, key, start, end)

    def find_val(self, cfg, key, index=0, end_index=-1):
        """ :param cfg: ConfigFile
            :param key: name of searched key (str)
            returns ConfigSection object or None
        """
        if not isinstance(cfg, ConfigFile):
            raise(TypeError("cfg must be ConfigFile parameter"))

        key_start = self.find_key(cfg.buffer, key, index, end_index)
        return self.find_next_val(cfg, key, key_start, end_index)


    #######################################################
    ### CONFIGURATION fixes PART - END
    #######################################################

    def is_config_changed(self):
        """
        Checks if the configuration files changed.
        """
        # FIXME: not sure what this should do
        return False
        with open(VALUE_ALLCHANGED, "r") as f:
            files = f.read()
            for f in self.FILES_TO_CHECK:
                found = re.findall(f.path, files)
                if found:
                    return True
        return False

    def is_file_loaded(self, path=""):
        """
        Checks if the file with a given 'path' is already loaded in FILES_TO_CHECK.
        """
        for f in self.FILES_TO_CHECK:
            if f.path == path:
                return True
        return False

    def new_config(self, path, parent=None):
        config = ConfigFile(path)
        self.FILES_TO_CHECK.append(config)
        return config

    def load_included_files(self):
        """
        Finds the configuration files that are included in some configuration
        file, reads it, closes and adds into the FILES_TO_CHECK list.
        """
        #TODO: use parser instead of regexp
        pattern = re.compile("include\s*\"(.+?)\"\s*;")
        # find includes in all files
        for ch_file in self.FILES_TO_CHECK:
            nocomments = self.remove_comments(ch_file.buffer)
            includes = re.findall(pattern, nocomments)
            for include in includes:
                # don't include already loaded files -> prevent loops
                if self.is_file_loaded(include):
                    continue
                try:
                    self.new_config(include)
                except IOError as e:
                    raise(ConfigParseError(
                            "Cannot open the configuration file: \"{path}\" included by \"{parent_path}\"".format(parent_path=ch_file.path, path=include), e)
                         )


    def load_main_config(self):
        """
        Loads main CONFIG_FILE.
        """
        try:
            self.new_config(self.CONFIG_FILE)
        except IOError as e:
            raise(ConfigParseError(
                "Cannot open the configuration file: \"{path}\"".format(path=self.CONFIG_FILE)), e)

    def load_config(self, path=None):
        """
        Loads main config file with all included files.
        """
        if path != None:
            self.CONFIG_FILE = path
        self.load_main_config()
        self.load_included_files()
    pass

class BindLegacyParser(BindParser):
    """ ISC BIND parser with unrelated pieces.

        Contains methods that should have separate methods or classes.
    """

    # FIXME: Not sure what should be changed
    OUTPUT_DIR = '/tmp'

    FIXED_CONFIGS = {}
    # Exit codes
    # TODO: Remove from here
    EXIT_NOT_APPLICABLE = 0
    EXIT_PASS = 1
    EXIT_INFORMATIONAL = 2
    EXIT_FIXED = 3
    EXIT_FAIL = 4
    EXIT_ERROR = 5


    def log_info(self, msg):
        print(msg)

    def fixed_config(self, cfg):
        if cfg.path in self.FIXED_CONFIGS:
            return self.FIXED_CONFIGS[cfg.path]
        else:
            for c in self.FILES_TO_CHECK:
                if cfg.path == c.path:
                    return c

    def write_fixed_configs_to_disk(self, result, sol_text):
        """
        Writes fixed configs in the respective directories.
        """
        if result > self.EXIT_FIXED:
            output_dir = os.path.join(self.OUTPUT_DIR, "dirtyconf")
            sol_text.add_solution("The configuration files could not be fixed completely as there are still some issues that need a review.")
        else:
            output_dir = os.path.join(self.OUTPUT_DIR, "cleanconf")
            sol_text.add_solution("The configuration files have been completely fixed.")

        for path in self.FIXED_CONFIGS:
            config = self.FIXED_CONFIGS[path]
            curr_path = os.path.join(output_dir, path[1:])

            # create dirs to make sure they exist
            try:
                os.makedirs(os.path.dirname(curr_path))
            except OSError as e:
                # if the dir already exist (errno 17), pass
                if e.errno == 17:
                    pass
                else:
                    raise e

            with open(curr_path, "w") as f:
                f.write(config.buffer)
            msg = "Written the fixed config file to '" + curr_path + "'"
            self.log_info(msg)
            sol_text.add_solution(msg)

    def new_config(self, path, parent=None):
        if not parent is None:
            self.log_info("Include statement found in \"{parent_path}\": "
                     "loading file \"{path}\"".format(
                             parent_path=parent.path, path=include))
        else:
            self.log_info("Loading the configuration file: \"{path}\"".format(path=path))
        super(self.__class__, self).new_config(path, parent)

    #######################################################
    ### CONFIGURATION CHECKS PART - END
    #######################################################
    ### CONFIGURATION fixes PART - BEGIN
    #######################################################
    def change_val(self, config, section, key, val):
        """
        Change value of key inside the section.

        val has to include all characters, including even curly brackets or quotes.
        Return modified string or None.
        """
        index = self.find_key(config, section)
        if index == -1:
            return None

        # find boundaries of the section
        index = self.find_next_token(config, index)
        if index == -1 or config[index] != "{":
            # that's really unexpected situation - maybe wrong config file
            return None
        end_index = self.find_closing_char(config, index)
        if end_index == -1 or config[end_index] != "}":
            # invalid config file?
            return None

        # find boundaries of value
        index, end_index = self.find_val_bounds_of_key(config, key, index+1, end_index)
        if -1 in [index, end_index] or config[index] != "\"":
            return None

        return config[:index] + val + config[end_index+1:]

    def log_statement(self, key, v):
        if v is None:
            self.log_info('Statement {stm} not found'.format(stm=key))
        else:
            self.log_info('Statement {stm} bounds {start}-{end}: {text}'.format(
                    stm=key, start=v.start, end=v.end, text=v.value()
                    ))

    def fix_statement(self, cfg, section, key, val, add_missing=False):
        """Add or change statement into the section of the config file.
       
        :param cfg: ConfigFile object 
        :param section: (sectionname, start, end) tuple with name and start and stop indexes, returned by find_val_bounds_of_key
        :param key: option name to replace value
        :param val: new value for option key
        """
        if not isinstance(cfg, ConfigFile):
            raise(TypeError("cfg must be ConfigFile parameter"))

        fixed_config = None
        config = self.fixed_config(cfg)
        v = self.find_val(config, key,
                section.start+1, section.end)
        if v is not None:
            val_correct = (val == v.value())
            self.log_statement(key, v)
            if not val_correct:
                fixed_config = self.change_val(config.buffer, section.name, key, val)
        else:
            self.log_statement(key, v)

        if fixed_config is None and add_missing:
            fixed_config = self.add_keyval(config.buffer, section.name, key, val)
                
        if v != None and val_correct:
            # value is already correct one
            config.status = self.EXIT_PASS
            return True
        if fixed_config is None:
            # value could not be changed or added
            config.status = self.EXIT_FAIL
            return False
        else:
            config.buffer = fixed_config
            config.status = self.EXIT_FIXED
            self.FIXED_CONFIGS[config.path] = config
            return True

    def add_keyval(self, config, section, key, val):
        """
        Add key with value to the section.

        val has to include all characters, including even curly brackets or quotes.
        Return modified string or None.
        """
        index = self.find_key(config, section)
        if index == -1:
            return None

        # find end of the section
        index = self.find_next_token(config, index)
        if index == -1 or config[index] != "{":
            # that's really unexpected situation - maybe wrong config file
            return None
        index = self.find_closing_char(config, index)
        if index == -1 or config[index] != "}":
            # invalid config file?
            return None

        new_config = "%s\n\t%s %s;\n%s" % (config[:index], key, val, config[index:])
        return new_config

