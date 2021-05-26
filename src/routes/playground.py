from fastapi import APIRouter, HTTPException

router = APIRouter(prefix="/playground")


@router.get(
    "/",
    summary="Return a list of guide to the playground",
    tags=["play"],
)
def list_activities():
    return {"message": "Welcome to the Playground"}
