
resource "local_file" "my_local_file" {
  filename = "my_automated_file.txt"
  content  = "Hey, My name is Deepak. This file is being created using terraform"
  #path     = "/home/deepak.kumar30/Desktop/"
}