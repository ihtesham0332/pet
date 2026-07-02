from fastapi import Query
from typing import Optional
from pydantic import BaseModel


class PaginationParams:
    def __init__(
        self,
        page: int = Query(1, ge=1, description="Page number"),
        limit: int = Query(20, ge=1, le=100, description="Items per page"),
    ):
        self.page = page
        self.limit = limit
        self.skip = (page - 1) * limit


class PaginatedResponse(BaseModel):
    items: list
    total: int
    page: int
    limit: int
    pages: int
