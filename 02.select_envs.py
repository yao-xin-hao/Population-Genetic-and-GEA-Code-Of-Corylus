import os,sys,re
import numpy as np
from decimal import *

def help():
    print('python3 xx.py cor_betweenenvs.txt corrlation [envs you want keep,split by \",\"]')
    sys.exit()
def read_betweenenv(file_):
    with open(file_) as fp:
        line=fp.readline().strip().split('\t')
        all_names=np.array(line[1:])
        all_cors=[]
        for line in fp:
            line=line.strip().split('\t')
            all_cors.append([Decimal(x) for x in line[1:]])
    all_cors=np.array(all_cors)
    return all_names,all_cors
def keep_for_arm_envs(all_names,all_cors):
    for keep_env in keep_envs:
        keep_env_highship=all_names[(abs(all_cors[all_names==keep_env,...])>=cor)[0]]
        for env in keep_env_highship:
            if env ==keep_env:
                continue
            else:
                if env in keep_envs:
                    raise ValueError("%s and %s have a high ship"%(keep_env,env))
                else:
                    all_cors=np.delete(all_cors,all_names==env,axis=0)
                    all_cors=np.delete(all_cors,all_names==env,axis=1)
                    all_names=np.delete(all_names,all_names==env,axis=0)
    return all_names,all_cors
def rm_high_ship(all_names,all_cors):
    all_highship_list=[]
    for env in all_names:
        env_highship=all_names[(abs(all_cors[all_names==env,...])>=cor)[0]]
        all_highship_list.append([env,len(env_highship)])
    all_highship_list.sort(key=lambda x:-x[1])
    if all_highship_list[0][1]==1:
        return all_names
    else:
        all_cors=np.delete(all_cors,all_names==all_highship_list[0][0],axis=0)
        all_cors=np.delete(all_cors,all_names==all_highship_list[0][0],axis=1)
        all_names=np.delete(all_names,all_names==all_highship_list[0][0],axis=0)
        return rm_high_ship(all_names,all_cors)

try:
    cor_betweenenvs=sys.argv[1]
    cor=float(sys.argv[2])
except:
    help()

keep_envs=[]
if len(sys.argv) > 3:
    keep_envs=sys.argv[3].split(',')

all_names,all_cors=read_betweenenv(cor_betweenenvs)
if keep_envs:
    all_names,all_cors=keep_for_arm_envs(all_names,all_cors)

keep_envs=rm_high_ship(all_names,all_cors)
for env in keep_envs:
    print(env)
