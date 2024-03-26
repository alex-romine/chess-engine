# Define custom function directory
ARG FUNCTION_DIR="/function"

FROM python:3.11 as build-image

# Include global arg in this stage of the build
ARG FUNCTION_DIR

# Copy function code
RUN mkdir -p ${FUNCTION_DIR}
COPY requirements.txt /tmp

# Install the function's dependencies
RUN pip install \
    --target ${FUNCTION_DIR} \
        awslambdaric

RUN pip install \
    -t ${FUNCTION_DIR} \
    -r /tmp/requirements.txt

COPY app/ ${FUNCTION_DIR}/app/

# Use a slim version of the base Python image to reduce the final image size
FROM python:3.11-slim

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

# Set runtime interface client as default command for the container runtime
ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
# Pass the name of the function handler as an argument to the runtime
CMD [ "app.main.handler" ]