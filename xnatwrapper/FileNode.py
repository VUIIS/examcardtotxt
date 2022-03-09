class FileNode(object):
    def __init__(self, ID, typename=None, filename=None, attrib=None):
        self.ID = ID
        self.typename = typename
        self.filename = filename
        if attrib:
            self.attrib = attrib
        else:
            self.attrib = {}