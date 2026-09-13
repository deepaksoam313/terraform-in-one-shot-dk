def result(students):
    highest_mark=0
    highest_name=""

    for name,mark in students.items():
       if mark > highest_mark:
           highest_mark=mark
           highest_name=name


    print(highest_mark)
    print(highest_name)
        

def word_count():
    word = "apple banana apple amrod kela apple banana"

    list1= word.split()
    count={}

    for i in list1:
        if i in count:
            count[i] += 1
        else:
            count[i] =1
    print(count)

if __name__ =="__main__":
    students = {
    "Deepak": 85,
    "Rahul": 72,
    "Amit": 91,
    "Priya": 78
}

    result(students)
    word_count()