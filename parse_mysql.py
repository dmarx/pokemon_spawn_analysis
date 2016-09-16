# Let's write a lazy mysqldbexport parser

def yield_rows(f, delim=',', str_delim="'", row_container='()', term=';'):
    vals = []
    accum = ''
    in_str = False
    firstchar=True
    while True:
        c = f.read(1)
        if not c:
            print ("unexpected EOF. Yielding remainder before exiting.")
            yield vals
            break
        
        if c == row_container[0]:
            vals = []
            accum = ''
            in_str = False
            firstchar=True
            continue
        if c == row_container[1]:
            vals.append(accum)
            yield vals
            c = f.read(1)
            if c == delim:
                vals = []
                accum = ''
                in_str = False
                firstchar=True
                continue
            elif c == term:
                return vals
            else:
                print('Expected delimiter, got: ' + c)
                raise('foobar')
        
        if not in_str and c == str_delim:
            in_str = True
            continue
        if in_str and c == str_delim:
            in_str = False
            continue
        
        if not in_str and c == delim:
            vals.append(accum)
            accum = ''
            continue
        
        
        accum += c
        
def find_insert_stmt(f, max_read=0):
    i=0
    target1 = "INSERT INTO "
    target2 = " VALUES "
    accum = ''
    match1 = False
    tablename = ''
    tablename_done = False
    match2 = False
    
    while True:
        if max_read>0:
            i+=1
            #print(i)
            if i == max_read:
                raise('Nothing Found.')
        c = f.read(1)
        accum += c
        #print (accum)
        
        if not match1 and accum == target1:
            match1 = True
            accum = ''
            continue
        if match1 and not tablename_done:
            #accum += c
            if accum[0] == accum[-1] and len(accum)>2:
                tablename = accum[1:-1]
                accum = ''
                tablename_done = True
            continue
        if tablename_done:
            if accum == target2:
                return f, True, tablename
            elif accum == target2[:len(accum)]:
                continue
            else: 
                print("\n\nsomething's funny here.")
                print(accum)
                raise("Expected 'VALUES'")
        
        if not match1 and accum == target1[:len(accum)]:
            continue
        
        accum=''
    return f, False, None
        
def scan_file(fname):
    with open(fname, 'r') as f:
        data = {}
        while True:
            #f, insert_queued, tablename = find_insert_stmt(f, max_read=2000)
            f, insert_queued, tablename = find_insert_stmt(f)
            if insert_queued:
                if tablename != 'versions':
                    print ("FOUND INSTERT INTO", tablename)
                    if tablename not in data:
                        data[tablename] = []
                    for row in yield_rows(f):
                        data[tablename].append(row)
                    print( len(data[tablename]) )
                else:
                    #insert_queued = False
                    #continue
                    break
            else:
                break
    print(data.keys())
    return data
    
if __name__ == '__main__':
    import csv
    fname = 'pokemon_db_dump'
    data = scan_file(fname)
    
    for k in data.keys():
        with open(k+'.csv','w') as f:
            csv.writer(f).writerows(data[k])
        
                
                