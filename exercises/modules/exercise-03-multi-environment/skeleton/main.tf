# =============================================================================
# ROOT MODULE - Exercise 03: Multi-Environment Deployment
# =============================================================================
# Your mission: Deploy dev, staging, and prod environments using your modules.
# =============================================================================

# =============================================================================
# ENVIRONMENT CONFIGURATION
# =============================================================================
# This is the SINGLE SOURCE OF TRUTH for environment-specific settings.
# Each environment has different colors, messages, and versioning settings.
# =============================================================================

locals {
  environments = {
    dev = {
      site_content = {
        heading          = "Development Preview"
        message          = "Internal testing environment for the development team."
        background_color = "#e3f2fd"  # Light blue
        badge_color      = "#1976d2"  # Blue
      }
      enable_versioning = false  # Don't need versioning in dev
    }

    staging = {
      site_content = {
        heading          = "Staging Review"
        message          = "Pre-production environment for stakeholder review."
        background_color = "#fff8e1"  # Light yellow/amber
        badge_color      = "#f57c00"  # Orange
      }
      enable_versioning = false  # Optional for staging
    }

    prod = {
      site_content = {
        heading          = "Welcome to Acme Corp"
        message          = "Official company website. Handle with care!"
        background_color = "#e8f5e9"  # Light green
        badge_color      = "#388e3c"  # Green
      }
      enable_versioning = true  # ALWAYS version production!
    }
  }
}

# =============================================================================
# DEV ENVIRONMENT
# =============================================================================
# TODO: Create module "dev_website" using ./modules/s3-website
#       - bucket_name: "acme-dev-${var.unique_suffix}"
#       - environment: "dev"
#       - site_content: local.environments.dev.site_content
#       - enable_versioning: local.environments.dev.enable_versioning
#       - tags: Team = "marketing", Project = "campaign-preview"

# TODO: Create module "dev_cdn" using ./modules/cdn
#       - origin_domain: module.dev_website.website_endpoint
#       - environment: "dev"
#       - tags: Team = "marketing", Project = "campaign-preview"


# =============================================================================
# STAGING ENVIRONMENT
# =============================================================================
# TODO: Create module "staging_website" using ./modules/s3-website
#       - bucket_name: "acme-staging-${var.unique_suffix}"
#       - environment: "staging"
#       - site_content: local.environments.staging.site_content
#       - enable_versioning: local.environments.staging.enable_versioning
#       - tags: Team = "marketing", Project = "campaign-preview"

# TODO: Create module "staging_cdn" using ./modules/cdn
#       - origin_domain: module.staging_website.website_endpoint
#       - environment: "staging"
#       - tags: Team = "marketing", Project = "campaign-preview"


# =============================================================================
# PROD ENVIRONMENT
# =============================================================================
# TODO: Create module "prod_website" using ./modules/s3-website
#       - bucket_name: "acme-prod-${var.unique_suffix}"
#       - environment: "prod"
#       - site_content: local.environments.prod.site_content
#       - enable_versioning: local.environments.prod.enable_versioning
#       - tags: Team = "marketing", Project = "campaign-preview"

# TODO: Create module "prod_cdn" using ./modules/cdn
#       - origin_domain: module.prod_website.website_endpoint
#       - environment: "prod"
#       - tags: Team = "marketing", Project = "campaign-preview"
