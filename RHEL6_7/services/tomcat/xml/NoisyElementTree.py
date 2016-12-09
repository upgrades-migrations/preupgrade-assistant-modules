
import re
import ElementTree as ET
from ElementTree import _encode, _namespaces, _serialize

class NSElement(ET.Element):
    def __init__(self, tag, attrib={}, **extra):
        ET.Element.__init__(self, tag, attrib)

    def namespace(self, keep_brackets=False):
        "Extracts namespaces from tags"
        m = re.match("\{.*\}", self.tag)
        return ("{"+m.group(0)+"}" if keep_brackets else m.group(0)) if m else ""

    def iter_ignore_ns(self, tag=None):
        """
        Similar to xml.etree.ElementTree.Element.iter() but ignores namespaces.

        The default Element.iter function returns just the elements that correspond
        exactly to a given tag (or all elements when the tag is not set), so when a namespace
        is used for an element, the tag must contain a namespace too, otherwise the element will
        not be returned.

        This function returns an element when the element corresponds to a given tag ignoring namespaces,
        so you get all elements with the same tag regardless of namespaces.
        """
        if tag is None:
            yield self.iter()
        for elem in self.iter():
            if not isinstance(elem.tag, str):
                continue
            pos = elem.tag.rfind('}')
            if(elem.tag[pos+1:] == tag):
                yield elem

    def iter_same_ns(self, tag=None):
        """
        Similar to xml.etree.ElementTree.Element.iter() but only for the same namespaces.

        It is something between Element.iter() and Element.iter_ignore_ns().
        When a tag is specified, the function returns all elements corresponding to the given
        tag with same namespaces as the original element.

        E.g. element.tag  = "{http://foo.tar}bobika"
             element1.tag = "{http://foo.tar}pepa"
             element2.tag = "{any_ns}pepa"
             # element1 & element2 are children of element
             ....
             for i in element.iter_same_ns("pepa"):
                 # returns only element1
        """
        ns = self.namespace(True)
        for elem in self.iter():
            if not isinstance(elem.tag, str):
                continue
            if (tag is None) and elem.tag.startswith(ns):
                yield elem
            elif (tag is not None) and (elem.tag == ns+tag):
                yield elem


class CommentTreeBuilder(ET.XMLTreeBuilder):
    "XMLTreeBuilder, which keeps XML comments, includes comments outside root"

    def __init__(self, html=0, target=None):
        ET.XMLTreeBuilder.__init__(self, html, target)
        self._parser.CommentHandler = self.handle_comment
        # this will contain all comments in XML - see NoisyElementTree.parse()
        self._commentElemList = []

    def handle_comment(self, data):
        self._target.start(ET.Comment, {})
        self._target.data(data)
        self._commentElemList.append(self._target.end(ET.Comment))

    def _end(self, tag):
        elem = self.target.end(self._fixname(tag))
        self._commentElemList.append(elem)
        return elem

    def get_comments(self):
        return self._commentElemList


### ugly solution to keep an ugly license ###

class NoisyElementTree(ET.ElementTree):
    """
    It is similar to ElementTree, but contains comments prior to the root node.

    Unfortunately, some programmers still have troubles to understand an XML
    format and put the LICENSE text as a comment before the root node, even when
    the license should not be a part of an XML file.

    When you need to transform the file and you do not want to lose nodes around the root
    node, this solution provides a way to do it. In this case, only the comments
    before the root node will be kept aside, accessible through:
        self.get_comments_prior_root().
    """

    def __init__(self, element=None, file=None, comments_prior_root=list()):
        ET.ElementTree.__init__(self, element, file)
        self._comments_prior_root = comments_prior_root

    def get_comments_prior_root(self):
        return self._comments_prior_root

    def is_valid_tree(self):
        "Returns 'False' when comments outside of the root node exist. Otherwise returns 'True'."
        return len(self._comments_prior_root) == 0

    def parse(self, source, parser=None):
        if not parser:
            parser = XMLParser(target=CommentTreeBuilder())
        super(NoisyElementTree, self).parse(source, parser)
        in_root_elems = set([elem for elem in self._root.iter()])
        self._comments_prior_root = [elem for elem in parser.get_comments() if elem not in in_root_elems]
        return self._root

    def write(self, file_or_filename,
              # keyword arguments
              encoding=None,
              xml_declaration=None,
              default_namespace=None,
              method=None):
        if not method:
            method = "xml"
        elif method not in _serialize:
            # FIXME: raise an ImportError for c14n if ElementC14N is missing?
            raise ValueError("unknown method %r" % method)
        if hasattr(file_or_filename, "write"):
            file = file_or_filename
        else:
            file = open(file_or_filename, "wb")
        write = file.write
        if not encoding:
            if method == "c14n":
                encoding = "utf-8"
            else:
                encoding = "us-ascii"
        elif xml_declaration or (xml_declaration is None and
                                 encoding not in ("utf-8", "us-ascii")):
            if method == "xml":
                write("<?xml version='1.0' encoding='%s'?>\n" % encoding)
        # !!! Print ugly comments prior to root node !!!
        for ugly_comment in self._comments_prior_root:
            write("<!--%s-->\n" % _encode(ugly_comment.text, encoding))
        # !!! end of ugly part
        if method == "text":
            _serialize[method](write, self._root, encoding)
        else:
            qnames, namespaces = _namespaces(
                self._root, encoding, default_namespace
                )
            serialize = _serialize[method]
            serialize(write, self._root, encoding, qnames, namespaces)
        if file_or_filename is not file:
            file.close()

