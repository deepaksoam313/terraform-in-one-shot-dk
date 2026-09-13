print ("Deepak")

x=5
print(x)

y=str(x)
print(type(y))

fruits=['apple','banana','oranges']
x,y,z = fruits

print("the value is",y , x )

str="my name is deepak"
print (len(str))
print(str[0:17:2])
print ("my" in str)

b = "Hello, World!"
print(b[-5:-2])

a = " Hello, World! "
a=a.strip()
#print(a.strip()) # returns "Hello, World!" 

print(a.split(","))

num=20
print(f"My number is {num}")

thislist =["apple","my","krla"]

print(thislist[1])
print(len(thislist))

thislist = ["apple", "banana", "cherry", "orange", "kiwi", "melon", "mango"]
print(thislist[2:5])

thislist = ["apple", "banana", "cherry"]
thislist[1] = "blackcurrant"
print(thislist)

thislist = ["apple", "banana", "cherry"]
thislist[1:2] = ["blackcurrant"]
thislist.insert(2, "kela")
print(thislist) 

thislist1 = ["apple", "banana", "cherry"]
thislist1[1:3] = ["watermelon"]

thislist.extend(thislist1)
print(thislist)
thislist.sort(reverse=True)
print(thislist)

for x in thislist:
    print(x)
for x in range(len(thislist)):
    print(x)

name = "deepak"
print(name[::-1])