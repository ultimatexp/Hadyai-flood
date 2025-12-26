import Link from "next/link";
import { LayoutDashboard, PawPrint } from "lucide-react";

export default function AdminLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <div className="min-h-screen bg-gray-100 flex flex-col">
            {/* Admin Header */}
            <header className="bg-white shadow-sm z-10">
                <div className="container mx-auto px-4 h-16 flex items-center justify-between">
                    <div className="flex items-center gap-8">
                        <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2">
                            <LayoutDashboard className="w-6 h-6 text-blue-600" />
                            Admin Panel
                        </h1>

                        <nav className="hidden md:flex items-center gap-1">
                            <Link
                                href="/admin/cases"
                                className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors flex items-center gap-2"
                            >
                                <LayoutDashboard className="w-4 h-4" />
                                Cases
                            </Link>
                            <Link
                                href="/admin/pets"
                                className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-orange-600 hover:bg-orange-50 rounded-lg transition-colors flex items-center gap-2"
                            >
                                <PawPrint className="w-4 h-4" />
                                Pets
                            </Link>
                        </nav>
                    </div>

                    <div className="flex items-center gap-4">
                        <Link href="/" className="text-sm text-gray-500 hover:text-gray-900">
                            Back to Home
                        </Link>
                    </div>
                </div>
            </header>

            {/* Mobile Nav */}
            <div className="md:hidden bg-white border-b border-gray-200 overflow-x-auto">
                <div className="flex px-4 py-2 gap-2">
                    <Link
                        href="/admin/cases"
                        className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors flex items-center gap-2 whitespace-nowrap"
                    >
                        Cases
                    </Link>
                    <Link
                        href="/admin/pets"
                        className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-orange-600 hover:bg-orange-50 rounded-lg transition-colors flex items-center gap-2 whitespace-nowrap"
                    >
                        Pets
                    </Link>
                </div>
            </div>

            {/* Main Content */}
            <main className="flex-1 container mx-auto p-4 md:p-6 max-w-7xl">
                {children}
            </main>
        </div>
    );
}
