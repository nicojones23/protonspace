# ProtonSpace API boundary

This service owns external sessions, one-time CityOS ticket exchange, profiles, feed writes, comments, reactions, follows, and notifications. It must validate every write against the server session. The browser never receives Qbox credentials, database credentials, or trusted citizen IDs.

The existing `cityos_mobile` Lua feed is a compatibility surface and should be migrated to this API once the service is deployed. Until then, it remains explicitly marked as the embedded test fallback.

`POST /internal/cityos/tickets` is private and requires `X-CityOS-Ticket-Secret`. It is the only endpoint allowed to create an in-game ticket. Keep it on a private network or behind the API firewall.
