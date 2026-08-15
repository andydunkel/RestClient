# REST Requests

The first line contains the HTTP method and URL. Headers follow on separate lines. Add an empty line before the optional request body.

```http
POST https://example.com/api/items
Content-Type: application/json
Authorization: Bearer TOKEN

{
  "name": "Example"
}
```
