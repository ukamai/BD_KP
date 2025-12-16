from fastapi import APIRouter

from app.api.v1.routers.health import router as health_router
from app.api.v1.routers.projects import router as projects_router
from app.api.v1.routers.tasks import router as tasks_router
from app.api.v1.routers.catalog import router as catalog_router
from app.api.v1.routers.purchase_orders import router as purchase_router
from app.api.v1.routers.reports import router as reports_router
from app.api.v1.routers.batch_import import router as batch_import_router

api_router = APIRouter()
api_router.include_router(health_router, tags=["health"])
api_router.include_router(projects_router, prefix="/projects", tags=["projects"])
api_router.include_router(tasks_router, tags=["tasks"])
api_router.include_router(catalog_router, tags=["catalog"])
api_router.include_router(purchase_router, prefix="/purchase-orders", tags=["purchase_orders"])
api_router.include_router(reports_router, prefix="/reports", tags=["reports"])
api_router.include_router(batch_import_router, prefix="/inventory-transactions", tags=["batch_import"])
