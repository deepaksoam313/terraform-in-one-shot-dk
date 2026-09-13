# -----------------------------------------------
# Module input variables
# These are the "parameters" of the module
# -----------------------------------------------

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = false
}

variable "extra_tags" {
  description = "Additional tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
