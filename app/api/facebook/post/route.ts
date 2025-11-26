import { NextResponse } from 'next/server';

const FACEBOOK_PAGE_ID = process.env.FACEBOOK_PAGE_ID;
const FACEBOOK_ACCESS_TOKEN = process.env.FACEBOOK_PAGE_ACCESS_TOKEN;

export async function POST(request: Request) {
    try {
        const { message, link, imageUrl } = await request.json();

        console.log('Facebook credentials check:', {
            hasPageId: !!FACEBOOK_PAGE_ID,
            hasToken: !!FACEBOOK_ACCESS_TOKEN,
            pageId: FACEBOOK_PAGE_ID,
        });

        if (!FACEBOOK_PAGE_ID || !FACEBOOK_ACCESS_TOKEN) {
            console.error("Facebook credentials missing", {
                FACEBOOK_PAGE_ID: !!FACEBOOK_PAGE_ID,
                FACEBOOK_ACCESS_TOKEN: !!FACEBOOK_ACCESS_TOKEN
            });
            return NextResponse.json({ error: "Configuration error" }, { status: 500 });
        }

        let url = `https://graph.facebook.com/v18.0/${FACEBOOK_PAGE_ID}/feed`;
        let body: any = {
            message: message,
            link: link,
            access_token: FACEBOOK_ACCESS_TOKEN,
        };

        // If there's an image, post to /photos endpoint instead
        if (imageUrl) {
            url = `https://graph.facebook.com/v18.0/${FACEBOOK_PAGE_ID}/photos`;
            body = {
                url: imageUrl,
                caption: `${message}\n\n${link}`, // Append link to caption since photos don't have a link field
                access_token: FACEBOOK_ACCESS_TOKEN,
            };
        }

        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        const data = await response.json();

        if (!response.ok) {
            console.error("Facebook API Error:", data);
            return NextResponse.json({ error: data.error?.message || "Facebook API Error" }, { status: response.status });
        }

        return NextResponse.json({ success: true, id: data.id });

    } catch (error) {
        console.error("Server Error:", error);
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}
