#!/usr/bin/python3
''' 
Converts examcards from txt to csv files
Formatted for Redcap sync module

'''

from __future__ import print_function
import json
import re
import sys, getopt, os
import glob
import numpy as np
import csv
import pandas
import collections

def search_string_in_file(file_name, string_to_search, starting_line):
    """
    Search for given string in file starting at provided line number
    and return the first line containing that string,
    along with line numbers.
    :param file_name: name of text file to scrub
    :param string_to_search: string of text to search for in file
    :param starting_line: line at which search starts
    """
    line_number = 0
    list_of_results = []
    # Open file in read only mode
    with open(file_name, 'r') as read_obj:
        # Read all lines one by one
        for line in read_obj:
            line_number += 1
            if line_number < starting_line:
                continue
            else:
                line = line.rstrip()
                if re.search(r"{}".format(string_to_search),line):
                    # If yes add the line number & line as a tuple in the list
                    list_of_results.append((line_number,line.rstrip()))
    #Return list of tuples containing line numbers and lines where string is found
    return list_of_results


def main(argv):
    outdir = ''
    try:
            opts,args = getopt.getopt(argv, "ho:",["outdir="])
    except getopt.GetoptError:
        print('ConvertExamCard.py -o <outdir>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('ConvertExamCard.py -o <outdir>')
            sys.exit()
        elif opt in ("-o", "--outdir"):
            outdir = arg

    # Find examcard.txt and make .csv
    examcard_dir = outdir + "/ExamCard"
    os.chdir(examcard_dir)
    examcard_txt = glob.glob("*.txt")[0]
    basename, _ = os.path.splitext(examcard_txt)
    examcard_csv = basename + '.csv'    

    # Load examcard parameters and save to dict
    exampara_dir = "/opt/pipeline/examcard2txt/examcard_parameters.csv"
    ep = pandas.read_csv(exampara_dir)
    para_dict = ep.to_dict()

    # Read in CSV and save scan names to dict
    examcard_df = pandas.read_csv(examcard_txt,delimiter="\t")
    tmp = examcard_df.iloc[:60,:]

    scan_list = []
    check = 0
    for i, j in tmp.iterrows():
        if "Protocols:" in j[0]:
            check = 1
            continue
        if check == 1:
            if "Protocol Name:" in j[0]:
                check = 0
            elif '=====' in j[0]:
                continue
            else:
                name = re.split(r'\s{2,}',j[0])[0]
                scan_list.append(name)

    # Scan txt file for scan names, extract parameters
    scan_dict = {}
    scan_dict['scan_name'] = scan_list
    para_list = para_dict['Variable Names']

    for i in range(len(para_list)):
        scan_dict[para_list[i]] = []

    tmp=[]
    search_string=[]
    split_string=[]
    para_exam = para_dict['Selected Parameters']
    for scan in scan_list:
        string_to_search = 'Protocol Name:  ' + scan
        scan_start = search_string_in_file(examcard_txt,string_to_search,0)[0][0]
        scan_end = search_string_in_file(examcard_txt,'Protocol Name:  ',int(scan_start)+1)
        if not scan_end:
            scan_end = search_string_in_file(examcard_txt,'Converted by examcard2txt',0)

        for i in range(len(para_exam)):
            para = para_exam[i]
            tmp=search_string

            search_string = search_string_in_file(examcard_txt,para,scan_start)
            if search_string and search_string[0][0] > scan_end[0][0]:
                search_string = []
            if search_string and tmp != search_string:
                scan_start = search_string[0][0]
                split_string = search_string[0][1].split(':')
                split_string = split_string[-1].strip()[:99]
                scan_dict[para_list[i]].append(split_string)
            elif search_string and tmp[0][1] == search_string[0][1]:
                scan_start = search_string[0][0]+1
                search_string = search_string_in_file(examcard_txt,para,scan_start)
                if not search_string:
                    scan_dict[para_list[i]].append('NOT FOUND')
                else:    
                    split_string = search_string[0][1].split(':')
                    split_string = split_string[-1].strip()[:99]
                    scan_dict[para_list[i]].append(split_string)
            elif not search_string:
                scan_dict[para_list[i]].append('NOT FOUND')


    # Add parameters to csv
    # One scan per row, first column is scan name
    pd_ec = pandas.DataFrame.from_dict(scan_dict)
    basename, _ = os.path.splitext(examcard_txt)
    examcard_csv = basename + '.csv' 
    pd_ec.to_csv(examcard_csv, sep = ',', encoding = 'cp1251', index = False)


if __name__ == '__main__':
    main(sys.argv[1:])