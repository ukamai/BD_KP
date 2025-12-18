from fastapi import APIRouter

from app.api.v1.routers.health import router as health_router
from app.api.v1.routers.projects import router as projects_router
from app.api.v1.routers.tasks import router as tasks_router
from app.api.v1.routers.catalog import router as catalog_router
from app.api.v1.routers.purchase_orders import router as purchase_router
from app.api.v1.routers.reports import router as reports_router
from app.api.v1.routers.properties import router as properties_router
from app.api.v1.routers.rooms import router as rooms_router
from app.api.v1.routers.phases import router as phases_router
from app.api.v1.routers.work_types import router as work_types_router
from app.api.v1.routers.contractors import router as contractors_router
from app.api.v1.routers.contracts import router as contracts_router
from app.api.v1.routers.inventory_transactions import router as inventory_transactions_router
from app.api.v1.routers.defects import router as defects_router
from app.api.v1.routers.acceptance_acts import router as acceptance_acts_router

from app.api.v1.routers.batch_import import (
    router as batch_import_router,
    public_router as batch_import_public_router,
)
from app.api.v1.routers.import_errors import router as import_errors_router

api_router = APIRouter()

api_router.include_router(health_router, tags=["health"])
api_router.include_router(projects_router, prefix="/projects", tags=["projects"])
api_router.include_router(tasks_router, tags=["tasks"])
api_router.include_router(catalog_router, tags=["catalog"])
api_router.include_router(purchase_router, prefix="/purchase-orders", tags=["purchase_orders"])
api_router.include_router(reports_router, prefix="/reports", tags=["reports"])

api_router.include_router(properties_router, prefix="/properties", tags=["properties"])
api_router.include_router(rooms_router, prefix="/rooms", tags=["rooms"])
api_router.include_router(phases_router, prefix="/phases", tags=["phases"])
api_router.include_router(work_types_router, prefix="/work-types", tags=["work_types"])
api_router.include_router(contractors_router, prefix="/contractors", tags=["contractors"])
api_router.include_router(contracts_router, prefix="/contracts", tags=["contracts"])
api_router.include_router(inventory_transactions_router, prefix="/inventory-transactions", tags=["inventory_transactions"])
api_router.include_router(defects_router, prefix="/defects", tags=["defects"])
api_router.include_router(acceptance_acts_router, prefix="/acceptance-acts", tags=["acceptance_acts"])

api_router.include_router(batch_import_router, prefix="/inventory-transactions", tags=["batch_import"])
api_router.include_router(batch_import_public_router, tags=["batch_import"])

api_router.include_router(import_errors_router, prefix="/import-errors", tags=["import_errors"])
