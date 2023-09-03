resource "azurerm_policy_definition" "mandatory_tag_match_pattern" {

  name                = "TagResourcesMatch"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Resources must match the ManagedBy tag - Definition"
  management_group_id = data.azurerm_management_group.tenant_root_group.id

  metadata = <<METADATA
    {
    "category": "Tags"
    }
METADATA

  policy_rule = <<POLICY_RULE
  {
    "if": {
      "not": {
        "anyOf": [
          {
            "field": "[concat('tags[', parameters('tagName'), ']')]",
            "match": "Terraform"
          },
          {
            "field": "[concat('tags[', parameters('tagName'), ']')]",
            "match": "Pulumi"
          },
          {
            "field": "[concat('tags[', parameters('tagName'), ']')]",
            "match": "Automation"
          },
          {
            "field": "[concat('tags[', parameters('tagName'), ']')]",
            "match": "Manual"
          }
        ]
      }
    },
    "then": {
      "effect": "deny"
    }
  }
POLICY_RULE

  parameters = <<PARAMETERS
    {
      "tagName": {
        "type": "String",
        "metadata": {
          "displayName": "Tag Name",
          "description": "Name of the tag, such as 'ManagedBy'"
        }
      }
    }
PARAMETERS
}

resource "azurerm_management_group_policy_assignment" "mandatory_tag_pattern" {

  name                 = "ManagedByTag"
  display_name         = "Resources must match the ManagedBy tag - Assignment"
  policy_definition_id = azurerm_policy_definition.mandatory_tag_match_pattern.id
  management_group_id  = data.azurerm_management_group.tenant_root_group.id

  non_compliance_message {
    content = "The ManagedBy tag is required in all resources which supports tags within this tenant and should be one of 'Terraform', 'Pulumi', 'Automation', or 'Manual'."
  }

  parameters = <<PARAMETERS
    {
      "tagName":{ 
        "value": "ManagedBy"
      }
    }
  PARAMETERS
}
