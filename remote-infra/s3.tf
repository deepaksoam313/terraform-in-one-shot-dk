resource "aws_s3_bucket" "s3_state_bucket" {
  bucket = "tf-state-terra-deepak"
  force_destroy = true

  tags = {
    Name = "s3-state-bucket-test"
  }

}