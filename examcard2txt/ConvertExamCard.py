#!/usr/bin/python3

'''
Inputs:
    -i: Filename of examcard in dicom format (full path)
    -o: output directory
    -p: XNAT project name

Outputs:
    .html and .txt version of examcard

'''

import base64
import itertools
import logging
import os
import shutil
import subprocess
import xml.dom.minidom
import sys
import getopt
from datetime import date
from lxml import etree

from FileNode import FileNode
from FileNodeFactory import FileNodeFactory
from ExamCardRename import ExamCardNode,ExamCardNodeFactory

def main(argv):
    examcard = ''
    outdir = ''
    project = ''
    try:
            opts,args = getopt.getopt(argv, "hi:o:p:",["examcard=","outdir=","project="])
    except getopt.GetoptError:
        print('ConvertExamCard.py -i <examcard.dcm> -o <outdir> -p <project>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('ConvertExamCard.py -i <examcard.dcm> -o <outdir> -p <project>')
            sys.exit()
        elif opt in ("-i", "--examcard"):
            examcard_file = arg
        elif opt in ("-o", "--outdir"):
            outdir = arg
        elif opt in ("-p", "--project"):
            project = arg


    EXAMCARD_TAG = "200110C8"
    SQ_TAG = "20051132"  # Indicates sequence with unknown width
    BLOB_TAG = "20051144"  # Indicates unknown tag and data

    ec_obj = ExamCardNodeFactory(outdir,'ExamCard');
    examcard = os.path.basename(examcard_file)

    params = {'calendar_date':date.today(),'study_name':project}
    ec_obj.attrib = ec_obj.get_query(params)

    mytup = ('1')  # maybe replace this with session
    myit =iter(mytup)
    ec_obj.subnodes=ec_obj.generate_node(myit,ec_obj)

    logger = logging.getLogger('xnat_task')

    ec_obj.subnodes['filename'] = os.path.join(outdir,'ExamCard',examcard)

    subnode = ec_obj.subnodes
    dicom_filename = subnode['filename']
    basename, _ = os.path.splitext(os.path.basename(dicom_filename))

    xml_filename = os.path.join(ec_obj.filename, basename) + '.xml'

    blob_dir = os.path.join(ec_obj.filename, SQ_TAG)
    blob_filename = os.path.join(blob_dir, '1', BLOB_TAG)

    status = subprocess.call(['dcm2xml', '-x', BLOB_TAG, '-o',
        xml_filename, subnode['filename']])

    parser = etree.XMLParser(huge_tree=True)  # Needed for large XML

    root = etree.parse(xml_filename, parser)

    empty_generator = itertools.count(1)
    exam_card_name = '{0:03d}'.format(next(empty_generator))

    for node in root.findall('attr'):
        if node.attrib['tag'] == EXAMCARD_TAG:
            if node.text:
                exam_card_name = node.text
            break

    new_filename = os.path.join(ec_obj.filename,
       exam_card_name) + '.ExamCard'

    c = itertools.count(0)

    while os.path.exists(new_filename):
        new_filename = os.path.join(ec_obj.filename,
            exam_card_name) + "{0:03}".format(next(c)) + '.ExamCard'

    blob_xml = etree.parse(blob_filename, parser)
    blob_tag = blob_xml.find("{*}ExamCardBlob")

    subdirectories = os.path.dirname(new_filename)
    if subdirectories:
        try:
            os.makedirs(subdirectories)
        except OSError:
            pass

    with open(new_filename, "wb") as blob_file:
        decoded = base64.b64decode(blob_tag.text)
        blob_file.write(decoded)

    out, err = subprocess.Popen(['perl', '/opt/pipeline/examcard2txt/examcard2txt.pl',
        '-nodata',new_filename],stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

    #out, err = subprocess.Popen(['perl', '/opt/pipeline/examcard2txt/examcard2txt/examcard2txt.pl',
    #    '-nodata',new_filename],stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

    logger.debug('out,err "{0},{1}"'.format(out,err))
    shutil.rmtree(blob_dir)     # Remove the blob directory
    os.remove(xml_filename)     # Remove the converted xml
    os.remove(dicom_filename)   # Remove original dicom

if __name__ == '__main__':
    main(sys.argv[1:])