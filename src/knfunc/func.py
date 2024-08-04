import os
import sys
import re
import time

from parliament import Context, event
from mindwm.neomodel import TmuxPane
from mindwm.models import TouchEvent
from cloudevents.http import from_http
from cloudevents import abstract, conversion
from neomodel import db
from neomodel import config

# logs and traces
func_name = "func_touch"
import otlp
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator
(logger, tracer) = otlp.init(func_name)

@event
def main(context: Context):
    event = context.cloud_event
    # NOTE: need to fetch a traceId part from the `traceparent` field value
    te = TouchEvent.from_json(conversion.to_json(event))
    ctx = TraceContextTextMapPropagator().extract(carrier=event)

    config.DATABASE_URL = os.environ["NEO4J_BOLT_URL"]


    with tracer.start_as_current_span("processing", context=ctx) as span:
        update_query = f"""
        MATCH (n)
        WHERE ID(n) IN {te.data.ids}
        CALL apoc.path.expandConfig(n, {{
          relationshipFilter: "<",
          minLevel: 1,
          bfs: true
        }}) YIELD path
        UNWIND nodes(path) as node
        UNWIND relationships(path) as r
        SET node.atime = timestamp()
        SET r.atime = timestamp()
        RETURN DISTINCT node, r
        """
        logger.debug(f"start processing: {event} {update_query}")
        db.cypher_query(update_query)

    with tracer.start_as_current_span("reply", context=ctx) as span:
        return "", 200

def test():
    print("test hello!")

if __name__ == "__main__":
    test()
