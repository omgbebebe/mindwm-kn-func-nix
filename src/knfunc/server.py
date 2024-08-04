from parliament import server
import os
from pathlib import Path
from waitress import serve

def run():
    path = Path(os.path.abspath(__file__))
    basedir = path.parent.absolute()
#    print(f"load func from: {basedir}")
    func = server.load(basedir)
    app = server.create(func)
    serve(app, listen='0.0.0.0:8080')

if __name__ == "__main__":
    run()

