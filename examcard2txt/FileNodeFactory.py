import os
import logging


class FileNodeFactory(object):
    def __init__(self, node_cls, typename, filename, attrib=None):
        self.node_cls = node_cls
        self.typename = typename
        self.filename = filename
        self.attrib = attrib
        self.subnodes = []
        self.create_dir()

    def create_dir(self):
        if not os.path.exists(self.filename):
            os.makedirs(self.filename)

    def create_node(self, *args, **kwargs):
        node =  self.node_cls(*args, **kwargs)
        self.subnodes.append(node)
        return node

    def collect_nodes_from_folder(self):
        self.subnodes = []
        for root, dirs, files in os.walk(self.filename):
            for f in files:
                filename = os.path.join(root, f)
                self.create_node(ID=None, filename=filename)

    def clean_nodes_in_folder(self):
        #Delete files that are not in the subnode list
        logger = logging.getLogger('gstudy_task')
        subnode_filenames = [node.filename for node in self.subnodes]
        for root, dirs, files in os.walk(self.filename):
            for f in files:
                filename = os.path.join(root, f)
                if filename not in subnode_filenames:
                    os.remove(filename)

    def clear_nodes(self):
        self.subnodes = []

    def identify_object(self, attrib):
        raise NotImplementedError

    def post_process_retrieval(self):
        raise NotImplementedError