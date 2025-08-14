This is a more complex example. It is extracted from a real-life PHP Symfony application.

Here, we use the same OCI image for 3 different
purposes :

- the API server (using PHP FPM), managed by a deployment
- cron jobs (using the PHP CLI interpreter),
- and a set of asynchronous 'worker' pods consuming messages via the [Symfony messenger component](https://symfony.com/doc/current/components/messenger.html). These are managed by another deployment.

Each usage corresponds to a role : 'api', 'cron', or 'worker'.

Init scripts are almost the same for every role, except an additional one for 'api' to retrieve the JWT public key from keycloak.

Start scripts are, of course, very different. Note that the 'cron' start script returns control, while 'api' and 'worker' don't. Obviously, if a start script for a deployment/statefulset pod exits, the container is destroyed.
