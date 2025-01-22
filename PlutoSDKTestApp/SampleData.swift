import PlutoSwiftSDK

enum SampleData {
    static let manifest = ManifestFile(
        manifestVersion: "2",
        id: "reddit-user-karma",
        title: "Total Reddit Karma",
        description: "Generate a proof that you have a certain amount of karma",
        prepareUrl: "https://old.reddit.com/login/?dest=https%3A%2F%2Fold.reddit.com%2F",
        request: ManifestFileRequest(
            method: .POST,
            url: "https://gql.reddit.com/",
            headers: ["Authorization": "Bearer <% authToken %>"],
            body: AnyCodable([
                "id": "db6eb1356b13",
                "variables": [
                    "name": "<% userId %>"
                ]
            ]),
            vars:  ["userId": ManifestVars(), "authToken": ManifestVars()],
            extra: ManifestFileRequestExtra(
                headers: [
                    "User-Agent": "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36",
                    "Content-Type": "application/json"
                ]
            )
        ),
        response: ManifestFileResponse(
            status: "200",
            headers: ["Content-Type": "application/json"],
            body: ManifestFileResponse.ResponseBody(json: ["data", "redditorInfoByName", "karma", "total"])
        )
    )

    static let prepareJS = """
        function prepare(ctx, manifest) {
            const cookies = ctx.cookies;
            const doc = ctx.doc;

            try {
                // Auth Token
                if (cookies["token_v2"]) {
                    manifest.request.set("authToken", cookies["token_v2"].value);
                }

                // User ID
                const userLink = doc.querySelector('span.user > a[href*="/user/"]');
                if (userLink) {
                    manifest.request.set(
                        "userId",
                        userLink.getAttribute("href").split("/user/")[1].replace("/", "")
                    );
                }

                return (
                    !manifest.request.get("body").variables.name.includes("<%") &&
                    !!manifest.request.getHeader("Authorization")
                );
            } catch (e) {
                console.error("Error in getBody:", e);
                return false;
            }
        }
    """

    static let manifestUrl = URL(string: "https://raw.githubusercontent.com/pluto/attest-integrations/refs/heads/main/integrations/reddit-user-karma/manifest.dev.json")!
}
