

resource aws_s3_bucket my_s3_bucket{

    bucket="deepaksoam313-s3-test"
    region = "us-east-1"
    force_destroy ="true"
}