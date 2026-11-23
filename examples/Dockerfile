# The project owns its test/build toolchain. This example uses shell fixtures.
FROM node:24-bookworm-slim@sha256:dc26ae92c9fb15cf6b1d63e20f0944b2efe0f115b20e00be48fb23fceb061c54 AS test
ARG TEST_EXIT_CODE=0
RUN mkdir /reports \
    && printf '%s\n' "$TEST_EXIT_CODE" > /reports/exit-code \
    && if [ "$TEST_EXIT_CODE" = 0 ]; then \
         printf '<testsuite name="example" tests="1" failures="0"><testcase name="sample"/></testsuite>\n'; \
       else \
         printf '<testsuite name="example" tests="1" failures="1"><testcase name="sample"><failure/></testcase></testsuite>\n'; \
       fi > /reports/junit.xml

FROM scratch AS reports
COPY --from=test /reports/ /

FROM test AS checked
RUN test "$(cat /reports/exit-code)" = 0 \
    && printf 'console.log("hello from the release image")\n' > /app.js

FROM node:24-bookworm-slim@sha256:dc26ae92c9fb15cf6b1d63e20f0944b2efe0f115b20e00be48fb23fceb061c54 AS runtime
COPY --from=checked /app.js /app.js
USER node
CMD ["node", "/app.js"]
