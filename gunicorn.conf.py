import multiprocessing

bind = "0.0.0.0:6443"
workers = multiprocessing.cpu_count() * 2 + 1
keyfile = "/etc/ssl/certs/sketchings.key"
certfile = "/etc/ssl/certs/sketchings.csr"
worker_class = "uvicorn.workers.UvicornWorker"