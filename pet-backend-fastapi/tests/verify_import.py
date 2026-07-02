"""Verify the FastAPI backend imports and routes correctly."""
from app.main import app

print(f"App: {app.title} v{app.version}")

routes = [(r.path, list(r.methods)[0] if r.methods else "ANY")
          for r in app.routes if hasattr(r, "methods")]

print(f"Routes: {len(routes)}")
for path, method in sorted(routes):
    print(f"  {method:7s} {path}")
