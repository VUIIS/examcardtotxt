import base64
import itertools
import logging
import os
import shutil
import subprocess
import xml.dom.minidom

from lxml import etree

from FileNode import FileNode
from FileNodeFactory import FileNodeFactory


EXAMCARD_TAG = "200110C8"
SQ_TAG = "20051132"  # Indicates sequence with unknown width
BLOB_TAG = "20051144"  # Indicates unknown tag and data


class ExamCardNode(FileNode):
    def __init__(self, ID, filename=None, attrib=None):
        super(ExamCardNode, self).__init__(ID, "ExamCard", filename, attrib)
        
    def __repr__(self):
        return '<ExamCardNode ID {}, filename {}, attrib {}>'.format(self.ID,
                                                             self.filename,
                                                             self.attrib)
class ExamCardNodeFactory(FileNodeFactory):
    def __init__(self, root_dir, typename):
        super(ExamCardNodeFactory, self).__init__(node_cls=ExamCardNode,
            typename='ExamCard', filename=os.path.join(root_dir, 'ExamCard'),
            attrib={'SOPClassUID': '1.2.840.10008.5.1.4.1.1.66'})
    def get_query(self, params):
        return {
            "StudyInstanceUID": "*",
            "SeriesInstanceUID": "*",
            "SOPInstanceUID": "*",
            "SOPClassUID": self.attrib['SOPClassUID'],
            "StudyDate": params['calendar_date'],
            "PatientName": params['study_name'],
            "SeriesNumber": 0,
            "PatientBirthDate": "*",
            "PatientSex": "*",
            "ProtocolName": "ExamCard",
            "Manufacturer": "*",
        }
    def identify_object(self, attrib):
        return True
    def generate_node(self, id_gen, attrib):
        logger = logging.getLogger('gstudy_task')
        node = None
        if attrib.get('SeriesNumber') == 0:
            node = {
                'filename': None,
                'ID': next(id_gen),
                'typename': self.typename,
                'attrib': attrib,
            }
        return node
    def post_process_retrieval(self, gsroot, task_info):
        """ Extract the examcard file from the DICOM file by fixing the zip
            file header and renaming it to the appropriate name """
        logger = logging.getLogger('gstudy_task')
        empty_generator = itertools.count(1)
        for subnode in self.subnodes:
            #logger.debug("ExamCard filename: {0}".format(subnode.filename))
            #dcm2xml may have an OutOfMemoryError, in which case 'xmlrec_info'
            #will be blank and 'err' will show the stack
            dicom_filename = subnode.filename
            basename, _ = os.path.splitext(os.path.basename(dicom_filename))
            xml_filename = os.path.join(self.filename, basename) + '.xml'
            blob_dir = os.path.join(self.filename, SQ_TAG)
            blob_filename = os.path.join(blob_dir, '1', BLOB_TAG)
            status = subprocess.call(['dcm2xml', '-x', BLOB_TAG, '-o',
                xml_filename, subnode.filename])
            logger.debug('dcm2xml: status "{}"'.format(status))
            if status == 0:
                parser = etree.XMLParser(huge_tree=True)  # Needed for large XML
                root = etree.parse(xml_filename, parser)
                exam_card_name = '{0:03d}'.format(next(empty_generator))
                for node in root.findall('attr'):
                    if node.attrib['tag'] == EXAMCARD_TAG:
                        if node.text:
                            exam_card_name = node.text
                        break
                new_filename = os.path.join(self.filename,
                    exam_card_name) + '.ExamCard'
                #logger.debug('new_filename "{0}"'.format(new_filename))
                #Generate a new filename until one is available
                c = itertools.count(0)
                while os.path.exists(new_filename):
                    new_filename = os.path.join(self.filename,
                        exam_card_name) + "{0:03}".format(next(c)) + '.ExamCard'
                blob_xml = etree.parse(blob_filename, parser)
                blob_tag = blob_xml.find("{*}ExamCardBlob")
                #examcard_name may have directories, so we need to create it
                subdirectories = os.path.dirname(new_filename)
                if subdirectories:
                    try:
                        os.makedirs(subdirectories)
                    except OSError:
                        pass
                with open(new_filename, "wb") as blob_file:
                    decoded = base64.b64decode(blob_tag.text)
                    blob_file.write(decoded)
                subnode.filename = new_filename
                out, err = subprocess.Popen(['perl', '/home/dylan/Documents/examcard2txt/examcard2txt/examcard2txt.pl',
		    '-nodata',new_filename],stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
                logger.debug('out,err "{0},{1}"'.format(out,err))
                shutil.rmtree(blob_dir)  # Remove the blob directory
                os.remove(xml_filename)  # Remove the converted xml
            else:
                logger.error("removing node {0} because xml is empty: {1}"
                    .format(dicom_filename, status))
            #os.remove(dicom_filename)  # Remove the original file
        self.collect_nodes_from_folder()