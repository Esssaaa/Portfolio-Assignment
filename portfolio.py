# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 16:57:18 2019

@author: neils
"""

from gurobipy import *
import numpy as np
import mysql.connector
from matplotlib import pyplot as plt 
# represents authenticated password / connection to database
db = mysql.connector.connect(user = 'root', password = 'root', database = 'nasdaq', auth_plugin = 'mysql_native_password')
cur = db.cursor()
cur.execute('SELECT stock1, stock2, covariance FROM cov')
covariance = {}
for (stock1, stock2, cov) in cur:
    covariance[(stock1, stock2)] = cov
cur2 = db.cursor()
cur2.execute('SELECT stock, meanReturn FROM r')
means = {}
stocks = []
for(stock, avg) in cur2:
    means[stock] = avg
    stocks.append(stock)
risks = [.03, .1, .15, .2, .25 , .3, .35 , .4, .45, .5, .75]
obj_vals = []
for ER in risks: 
    m = Model("Portfolio Optimization")
    m.remove(m.getVars())
    m.remove(m.getConstrs())
    #ER = .12
    dec_vars = {}
    for i in means:
        dec_vars[i] = (m.addVar(vtype = GRB.CONTINUOUS, name = "stock {0}".format(i), lb = 0.0))
    port_constr = m.addQConstr(quicksum(dec_vars[i] for i in dec_vars), GRB.EQUAL, 1)
    max_risk = m.addQConstr(quicksum(dec_vars[i] * covariance[(i,j)] * dec_vars[j] for i in means for j in means), GRB.LESS_EQUAL, ER)
    m.update()
    m.setObjective(quicksum( dec_vars[i] * means[i] for i in means), GRB.MAXIMIZE) 
    m.update()
    m.optimize()
    obj_vals.append(m.objVal)
cur3 = db.cursor() 
begin = "INSERT INTO portfolio (expReturn, expRisk) values "
for o in range(len(obj_vals)):
    if o == len(obj_vals)-1:
        begin+= "({0}, {1});".format(obj_vals[o], risks[o])
    else:
        begin += "({0}, {1}), ".format(obj_vals[o], risks[o])
cur3.execute(begin)
db.commit()