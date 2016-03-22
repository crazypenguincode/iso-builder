#! /usr/bin/env python2
# -*- coding: utf-8 -*-
#

import sqlite3

class History(object):
    def __init__(self):
        self.cx=sqlite3.connect('history.db')
        self.cx.isolation_level = None
        self.cu = self.cx.cursor()

    def insert(self, job, status, log, iso, starttime, duration, pxe=0):
        self.cu.execute("insert into history (job, status, log, iso, starttime, duration,pxe) values(?,?,?,?,?,?,?)" , (job, status , log ,iso, starttime, duration,pxe))
        self.cx.commit()
    
    def update(self, job, status, log, iso,  startting, duration, pxe=0):
        self.cu.execute("update history set job='%s',status='%s',log='%s',starttime='%s',duration='%s',pxe='%s'  where iso='%s'" % (job, status , log ,startting, duration,iso, pxe))
        self.cx.commit()


    def fetchall(self):
        self.cu.execute("select * from history ORDER BY id DESC")
        return self.cu.fetchall()

    def fetch_by_key(self, key, value):
        self.cu.execute("select * from history where %s='%s' ORDER BY id DESC" % (key, value))
        return self.cu.fetchone()

    def delete(self, db_id):
        self.cu.execute("delete from history where id='%s'" % db_id)
        self.cx.commit()
        

if __name__ == "__main__":
    import datetime
    n=datetime.datetime.now()
    B=History()
    print B.fetchall()
    #B.insert('amd64','failed', 'a.log','amd64-iso', n , '30s')
    #B.update('amd64','failed', 'a.log','amd64-iso', n , '130s')
    #print B.fetch_by_key('id',2)
    print B.fetch_by_key('job','amd64')
    is_exists= True if B.fetch_by_key('id',1) else False
    print is_exists
