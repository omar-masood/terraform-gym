# =============================================================================
# ROOT MODULE - Exercise 02: CDN Module
# =============================================================================
# This demonstrates MODULE COMPOSITION - modules working together.
# The CDN module will depend on outputs from the S3 website module.
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Website Module (already complete from Exercise 01)
# -----------------------------------------------------------------------------
module "website" {
  source = "./modules/s3-website"

  bucket_name = "acme-marketing-dev-${var.unique_suffix}"
  environment = "dev"

  site_content = {
    heading          = "Development Preview"
    message          = "This is the internal development environment. Now with CloudFront CDN!"
    background_color = "#e3f2fd"
    badge_color      = "#1976d2"
  }

  tags = {
    Team    = "marketing"
    Project = "campaign-preview"
  }
}

# -----------------------------------------------------------------------------
# CloudFront CDN Module (TODO: Complete this!)
# -----------------------------------------------------------------------------
# Once you've built the cdn module, uncomment and complete this block:
# -----------------------------------------------------------------------------

# TODO: Uncomment and complete once your cdn module is ready
#
# module "cdn" {
#   source = "./modules/cdn"
#
#   # Wire the S3 module's output to this module's input!
#   origin_domain = module.website.website_endpoint
#   environment   = "dev"
#
#   tags = {
#     Team    = "marketing"
#     Project = "campaign-preview"
#   }
# }
