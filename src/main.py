import secure
from fastapi import FastAPI

app = FastAPI()

server = secure.Server().set("Secure")
hsts = secure.StrictTransportSecurity().include_subdomains().preload().max_age(2592000)
cache_value = secure.CacheControl().must_revalidate()

secure_headers = secure.Secure(server=server, hsts=hsts, cache=cache_value)


@app.middleware("http")
async def set_secure_headers(request, call_next):
    response = await call_next(request)
    secure_headers.framework.fastapi(response)
    return response


@app.get("/")
def read_root():
    return {"Hello": "World"}
