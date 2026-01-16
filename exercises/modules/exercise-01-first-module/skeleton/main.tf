# =============================================================================
# HARDCODED S3 STATIC WEBSITE
# =============================================================================
# This is what infrastructure looks like WITHOUT modules.
# Everything is hardcoded. To create a second environment, you'd copy-paste
# this entire file and change the values. That's the problem we're solving.
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "website" {
  bucket = "acme-marketing-dev-CHANGEME"  # <-- Hardcoded!

  tags = {
    Name        = "acme-marketing-dev-CHANGEME"  # <-- Hardcoded!
    Environment = "dev"                          # <-- Hardcoded!
    Team        = "marketing"                    # <-- Hardcoded!
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Website Configuration
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# -----------------------------------------------------------------------------
# Public Access Settings
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# -----------------------------------------------------------------------------
# Bucket Policy - Allow Public Read
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  depends_on = [aws_s3_bucket_public_access_block.website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Website Content
# -----------------------------------------------------------------------------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content_type = "text/html"
  
  # Hardcoded HTML content - imagine this is 500 lines of HTML...
  content = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Dev Preview | Acme Corp</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background-color: #e3f2fd;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .card {
          background: white;
          padding: 3rem;
          border-radius: 12px;
          box-shadow: 0 4px 20px rgba(0,0,0,0.1);
          text-align: center;
          max-width: 500px;
        }
        .badge {
          display: inline-block;
          background: #1976d2;
          color: white;
          padding: 0.5rem 1rem;
          border-radius: 20px;
          font-size: 0.875rem;
          font-weight: 600;
          text-transform: uppercase;
          margin-bottom: 1.5rem;
        }
        h1 { color: #1a1a1a; margin-bottom: 1rem; font-size: 2rem; }
        p { color: #666; line-height: 1.6; }
        .footer {
          margin-top: 2rem;
          padding-top: 1.5rem;
          border-top: 1px solid #eee;
          font-size: 0.75rem;
          color: #999;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <span class="badge">dev</span>
        <h1>Development Preview</h1>
        <p>This is the internal development environment for testing.</p>
        <div class="footer">
          Deployed with Terraform | Acme Corp
        </div>
      </div>
    </body>
    </html>
  HTML

  depends_on = [aws_s3_bucket_policy.website]
}
