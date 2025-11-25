import HelperAuthGuard from "@/components/auth/helper-auth-guard";

export default function HelperLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <HelperAuthGuard>
            {children}
        </HelperAuthGuard>
    );
}
