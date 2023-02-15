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
    scan_dict={}
    tmp=[]
    search_string=[]
    for scan in scan_list:
        scan_dict[scan] = []
        string_to_search = 'Protocol Name:  ' + scan
        scan_start = search_string_in_file(examcard_txt,string_to_search,0)[0][0]
        scan_end = search_string_in_file(examcard_txt,'Protocol Name:  ',int(scan_start)+1)
        if not scan_end:
            scan_end = search_string_in_file(examcard_txt,'Converted by examcard2txt',0)

        for para_options in para_dict.keys():
            for i in range(len(para_dict[para_options])):
                para = para_dict[para_options][i]

                tmp=search_string

                search_string = search_string_in_file(examcard_txt,para,scan_start)
                # verify that value is within scan range in examcard
                if search_string and search_string[0][0] > scan_end[0][0]:
                    search_string = []
                # verify that we are pulling unique values
                if search_string and tmp != search_string:
                    scan_start = search_string[0][0]
                    scan_dict[scan].append(search_string[0][1])
                elif search_string and tmp == search_string:
                    scan_start = search_string[0][0]+1
                    search_string = search_string_in_file(examcard_txt,para,scan_start)
                    scan_dict[scan].append(search_string[0][1])
                elif not search_string:
                    # Insert NOT FOUND if parameter is not in examcard
                    scan_dict[scan].append(para + ': NOT FOUND')

    # Adjust dict for redcap sync module
    # Append spaces to duplicate entries and remove entries > 100 characters in length
    uniq = {}

    for key in scan_dict.keys():
        seen = set()
        tmp = []
        uniq[key] = []
        for val in scan_dict[key]:
            if val not in seen and len(val) < 100:            
                seen.add(val)
                uniq[key].append(val)
            elif len(val) < 100:
                uniq[key].append(val + ' ')
                seen.add(val + ' ')
            else:
                uniq[key].append(val[:99])
                seen.add(val[:99])

        # Add parameters to csv
        # One scan per row, first column is scan name
        with open(examcard_csv, "w") as csv_file:
            for key in uniq.keys():
                csv_file.write("%s,%s\n"%(key,uniq[key]))


if __name__ == '__main__':
    main(sys.argv[1:])