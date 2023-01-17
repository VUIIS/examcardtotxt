# Converts examc cards from txt to csv files

import pandas
import glob
import os

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


    examcard_dir = outdir + "/ExamCard"
    os.chdir(examcard_dir)
    examcard_txt = glob.glob("*.txt")[0]
    basename, _ = os.path.splitext(examcard_txt)
    examcard_csv = basename + '.csv'    

    df = pandas.read_csv(examcard_txt,delimiter="\n")
    df_split = df[df.columns.values[0]].str.split(':',n=1,expand=True)
    df_split.columns = [df.columns.values[0],"Value"]
    df_split["Value"].str.strip()
    df_split.to_csv(examcard_csv, encoding='utf-8', index=False)