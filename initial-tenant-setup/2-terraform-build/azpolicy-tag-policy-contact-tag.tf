resource "azurerm_policy_definition" "mandatory_tag_contact_email" {
  name                = "MandatoryTagContactEmail"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Resources Must Contain 'Contact' Tag - Definition"
  management_group_id = data.azurerm_management_group.tenant_root_group.id
  metadata            = <<METADATA
    {
    "category": "Tags"
    }

METADATA


  policy_rule = <<POLICY_RULE
    {
      "if": {
        "allOf": [
          {
            "field": "[concat('tags[', parameters('tagName'), ']')]",
            "notLike": "[parameters('ContactEmail')]"
          }
        ]
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
          "description": "Name of the tag, such as 'environment'"
        }
      },
      "ContactEmail": {
        "type": "String",
        "metadata": {
          "displayName": "Email of user to contact",
          "description": "Value of the tag, such as 'joe@blogs.com'"
        }
      }
    }
PARAMETERS
}

resource "azurerm_management_group_policy_assignment" "mandatory_tag_contact" {
  name                 = "ContactTag"
  display_name         = "Resources must contain 'Contact' Tag - Assignment"
  policy_definition_id = azurerm_policy_definition.mandatory_tag_contact_email.id
  management_group_id  = azurerm_policy_definition.mandatory_tag_contact_email.management_group_id

  non_compliance_message {
    content = "The 'Contact' tag is required in all resources which supports tags within this tenant."
  }

  not_scopes = []
  parameters = <<PARAMETERS
    {
      "tagName":{ 
        "value": "Contact"
      },
      "ContactEmail": {
        "value": "*@libredevops.org"
      }
    }
  PARAMETERS
}