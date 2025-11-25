import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "tympremgrvknekswiaar.supabase.co",
      },
    ],
  },
};

export default nextConfig;
