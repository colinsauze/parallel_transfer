import sys

group_total=0
group_number=0
#the size limit for each group in bytes
#size_limit=650000000000
print(len(sys.argv))
print(sys.argv)
assert len(sys.argv) == 2
size_limit = int(sys.argv[1])

sizes = open("filesizes","r")

group = open("group_0","w")

for line in sizes:
    print("processing file ",line)
    size=line.split("\t")[0]
    filename=line.split("\t")[1]

    print("filename = ",filename," size = ",size)

    group.write(filename)
    group_total = group_total + int(size)

    print("group number = ",group_number," group size = ",(group_total/1000000),"MB")

    if group_total > size_limit:
        print(group_number,"has reached ",group_total, "creating another group")
        group.close()
        group_number+=1
        group_total=0
        group = open("group_"+str(group_number),"w")
