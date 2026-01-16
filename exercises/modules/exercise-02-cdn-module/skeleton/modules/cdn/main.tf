# =============================================================================
# CLOUDFRONT CDN MODULE
# =============================================================================
# TODO: Create a CloudFront distribution that serves content from an S3 origin
#
# This module should:
# 1. Create a CloudFront distribution
# 2. Configure it to use the S3 website endpoint as a custom origin
# 3. Enable HTTPS (redirect HTTP to HTTPS)
# 4. Apply appropriate tags
# =============================================================================

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# TODO: Define locals for tag management (similar to s3-website module)


# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------
# TODO: Create the aws_cloudfront_distribution resource
#
# Key configuration points:
# - enabled = true
# - is_ipv6_enabled = true
# - default_root_object = "index.html"
# - price_class = var.price_class
#
# Origin block:
# - Use custom_origin_config (not s3_origin_config) because S3 website
#   endpoints behave like web servers
# - origin_protocol_policy = "http-only" (S3 websites are HTTP only)
#
# Default cache behavior:
# - viewer_protocol_policy = "redirect-to-https" (force HTTPS!)
# - allowed_methods = ["GET", "HEAD", "OPTIONS"]
# - cached_methods = ["GET", "HEAD"]
#
# Restrictions:
# - geo_restriction with restriction_type = "none"
#
# Viewer certificate:
# - cloudfront_default_certificate = true (use *.cloudfront.net cert)
# -----------------------------------------------------------------------------

