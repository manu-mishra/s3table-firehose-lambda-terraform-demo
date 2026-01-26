# Lake Formation Permissions
resource "null_resource" "post_foundation" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Granting Lake Formation permissions..."
      
      ROLE_ARN="${aws_iam_role.firehose_role.arn}"
      ACCOUNT_ID="${data.aws_caller_identity.current.account_id}"
      BUCKET_NAME="${var.stack_name}"
      CATALOG_ID="$ACCOUNT_ID:s3tablescatalog/$BUCKET_NAME"
      DATABASE_NAME="${var.stack_name}"
      TABLE_NAME="${var.stack_name}"
      
      # Grant database permissions
      aws lakeformation grant-permissions \
        --principal DataLakePrincipalIdentifier=$ROLE_ARN \
        --permissions ALL \
        --permissions-with-grant-option ALL \
        --resource "{\"Database\":{\"CatalogId\":\"$CATALOG_ID\",\"Name\":\"$DATABASE_NAME\"}}" \
        --region ${var.region} || echo "Database permissions already exist"
      
      # Grant table permissions (ALL_TABLES wildcard)
      aws lakeformation grant-permissions \
        --principal DataLakePrincipalIdentifier=$ROLE_ARN \
        --permissions ALL ALTER DELETE DESCRIBE DROP INSERT \
        --resource "{\"Table\":{\"CatalogId\":\"$CATALOG_ID\",\"DatabaseName\":\"$DATABASE_NAME\",\"TableWildcard\":{}}}" \
        --region ${var.region} || echo "Table permissions already exist"
      
      # Grant column permissions (SELECT on specific table)
      aws lakeformation grant-permissions \
        --principal DataLakePrincipalIdentifier=$ROLE_ARN \
        --permissions SELECT \
        --resource "{\"TableWithColumns\":{\"CatalogId\":\"$CATALOG_ID\",\"DatabaseName\":\"$DATABASE_NAME\",\"Name\":\"$TABLE_NAME\",\"ColumnWildcard\":{}}}" \
        --region ${var.region} || echo "Column permissions already exist"
      
      echo "Lake Formation permissions granted successfully"
    EOT
  }

  depends_on = [
    aws_s3_bucket.error_bucket,
    aws_iam_role.firehose_role,
    aws_iam_role_policy.firehose_policy,
    aws_s3tables_table.table
  ]
}
