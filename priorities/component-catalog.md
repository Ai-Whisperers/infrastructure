# ParaguAI — Component, Section & Model Catalog

Everything we've built, ready to reuse across all client sites. Organized by category.

---

## 1. Content Architecture Patterns

We have **two distinct content architectures** in use:

### Pattern A: Static JSON Content (10+ sites)
**Used by:** superspuma, dayah, depiflash, 3md, magnolia, mantra, granja-cabral, 30vcs, stroopwafel, nudo, ozmontania

Single `content/es.json` with all text, loaded at build time. No DB, fully static.

**Content type system** (shared type definition across superspuma/dayah/depiflash):
```
types/content.ts → Content interface
  ├── Navigation      → labels, hrefs, CTA
  ├── HomeContent     → hero, stats, features, services, portfolio, testimonials, process, finalCta, newsletter
  │   ├── HeroContent     → headline, subheadline, ctas, image
  │   ├── StatItem        → value, label
  │   ├── FeatureItem     → title, description, icon
  │   ├── ServiceItem     → name, price, priceUsd?, description, delivery, whatsappCta?, crossSell?
  │   ├── PortfolioItem   → title, genre, image, slug, author?, amazonUrl?
  │   ├── BookItem        → title, format, achievement, platform?, platformUrl?
  │   ├── ProcessStep     → step, title, description
  │   └── Testimonial     → name, text, rating, book?, bookLink?
  ├── AboutContent    → story, credentials, values
  ├── FAQContent      → items: {question, answer, cta?}
  ├── WhatsAppContent → defaultMessage, serviceMessage, phone
  ├── ContactoContent → info: {phone, whatsapp, email, instagram, facebook, linkedin, address}
  └── FooterContent   → columns, paymentMethods, socials
```

### Pattern B: Multi-locale JSON Content (3 sites)
**Used by:** elviajero (es/en/gn), golden-visa (es/en/pt), duerksen (es/en)

Separate files per language, content wrapper with i18n.

**elviajero pattern:**
```
content/es.json, content/en.json, content/gn.json
Guarani (gn) support unique to elviajero
```

**golden-visa pattern:**
```
src/content/data.json          ← master file with all locales
src/content/types.ts            ← ContentData + LocalizedContent interfaces
src/content/index.ts            ← loader
LocaleContext + LanguageDropdown ← client-side language switching
```

**duerksen pattern:**
```
next-intl library ← i18n framework
lib/constants.ts               ← shared constants
lib/services-data.ts           ← service data
lib/blog-data.ts               ← blog data
```

### Pattern C: Database-backed (2 sites)
**Used by:** fun4me (Postgres + pg), elviajero (SQLite better-sqlite3)

**fun4me:** Custom pg auth (bcryptjs + JWT), pg@8 for CRUD
**elviajero:** SQLite at data/viajero.db, better-sqlite3

---

## 2. Shared Client-Kit Components

**Location:** `/root/superspuma/lib/client-kit/`

These are hard-copied into superspuma/dayah/depiflash repos. Not yet a proper npm package.

| Component | File | Props | Description |
|-----------|------|-------|-------------|
| Header | header.tsx | `{ logo?: string }` | Sticky top nav, white/95 backdrop-blur, 7 nav items hardcoded |
| Footer | footer.tsx | `{ businessName?: string }` | 4-column grid, navy bg, links hardcoded |
| WhatsApp Float | whatsapp-float.tsx | `{ phone?: string, message?: string }` | Fixed bottom-right, green bubble |
| CTA Banner | cta-banner.tsx | implicit (reads content/es.json) | Mid-page full-width CTA |
| Cookie Consent | cookie-consent.tsx | none | Bottom banner, sets localStorage |
| Mobile CTA | mobile-cta.tsx | implicit | Sticky bottom mobile bar |
| Process Section | process-section.tsx | implicit | Steps display from content |

**Problem:** These are tied to superspuma's nav structure — not truly generic for all clients. Need refactoring.

---

## 3. Rich Component Libraries (By Client)

### 3a. El Viajero — Full E-Commerce (~120 components)

**Standalone site:** richest component library in our fleet.

#### Commerce Core
| Component | What It Does |
|-----------|-------------|
| cart-context.tsx | Full cart state management (add, remove, quantity, multi-select) |
| cart-sidebar.tsx | Slide-out cart drawer |
| cart-merger.tsx | Merge guest → logged-in carts |
| cart-multi-select.tsx | Batch select cart items |
| cart-related.tsx | Related products in cart |
| cart-shipping.tsx | Shipping options in cart |
| checkout-stepper.tsx | Multi-step checkout wizard |
| order-review.tsx | Order summary before submit |
| order-timeline.tsx | Status timeline for orders |
| reorder-button.tsx | One-click reorder from history |

#### Product Experience
| Component | What It Does |
|-----------|-------------|
| image-gallery.tsx | Multi-image viewer with zoom |
| image-magnifier.tsx | Hover-to-zoom on product images |
| product-tabs.tsx | Tabbed product details |
| product-reviews.tsx | Star rating, reviews list |
| product-faq.tsx | Per-product FAQ accordion |
| product-modal.tsx | Quick-view modal |
| add-to-cart-button.tsx | Quantity + Add-to-cart |
| compare-checkbox.tsx | Select for comparison |
| recently-viewed-products.tsx | History strip |
| share-buttons.tsx | Social sharing |
| share-wishlist.tsx | Share wishlist via link |
| price-range.tsx | Price slider filter |
| price-usd.tsx | Dual-currency display (PYG/USD) |
| bulk-price.tsx | Volume pricing tiers |
| brand-filter.tsx | Filter by brand |
| search-autocomplete.tsx | Typeahead search |
| search-filters.tsx | Sidebar filter panel |

#### Promotions & Pricing
| Component | What It Does |
|-----------|-------------|
| coupon-input.tsx | Promo code entry |
| promo-codes.ts | Full promo engine (percentage/fixed/BOGO) |
| bundle.ts | Bundle optimization logic |
| bogo.ts | Buy-one-get-one validator |
| frequently-bought.ts | FBT cross-sell widget |
| auto-promo.ts | Auto-apply promotions |
| promo-carousel.tsx | Featured deals carousel |
| promo-from-url.tsx | URL-driven promo codes |
| billing-toggle.tsx | Payment method toggle |
| tax-display.tsx | Tax breakdown |
| delivery-calculator.tsx | Shipping cost estimator |
| delivery-estimator.tsx | Delivery date estimator |
| delivery-estimate-badge.tsx | Per-product delivery badge |
| pickup-option.tsx | Local pickup toggle |
| cod-option.tsx | Cash on delivery option |

#### Trust & Social
| Component | What It Does |
|-----------|-------------|
| newsletter-form.tsx | Email signup |
| reviews.ts | Review CRUD + moderation |
| feedback-button.tsx | Send feedback |
| notification-prefs.tsx | User notification settings |
| exit-intent.tsx | Exit-intent popup |
| share-whatsapp.tsx | WhatsApp share button |
| safe-image.tsx | Image error handling fallback |
| skeleton.tsx | Loading skeletons |
| empty-state.tsx | Empty state illustrations |
| reading-progress.tsx | Article reading progress bar |

#### User Account
| Component | What It Does |
|-----------|-------------|
| auth-wrapper.tsx | Auth guard wrapper |
| auth-context.tsx | Auth state management |
| api-auth.ts | Server-side auth + rate limiting |
| py-address-select.tsx | Paraguay address selector (dept/city) |
| profile-image.tsx | Avatar upload |
| saved-card.tsx | Saved payment methods |
| settings-notifications.tsx | Notification preferences |
| cancel-order-button.tsx | Order cancellation |
| undo-delete.tsx | Soft delete with undo toast |

#### Analytics & SEO
| Component | What It Does |
|-----------|-------------|
| analytics.ts | GA4 + custom events |
| json-ld.tsx | Structured data generator |
| article-json-ld.tsx | Article schema |
| category-breadcrumb-jsonld.tsx | Breadcrumb schema |
| faq-json-ld.tsx | FAQ schema |
| og-config.ts | Open Graph meta builder |
| seo-meta.ts | Page-level SEO metadata |

#### Admin
| Component | What It Does |
|-----------|-------------|
| admin-pdf.ts | Generate PDF invoices |
| export-csv.ts | Export orders to CSV |
| invoice.ts | Invoice generation |
| stock-history.ts | Stock change tracking |
| abandoned-cart.ts | Abandoned cart recovery |
| subscribers.json | Newsletter subscriber store |
| users.json | Local user store |
| promos.json | Promo code store |

#### UI Primitives
| Component | What It Does |
|-----------|-------------|
| ui.tsx | Shared UI primitives (buttons, inputs) |
| toast.tsx | Toast notifications |
| tooltip.tsx | Tooltip on hover |
| loading-bar.tsx | Top loading bar |
| dark-mode-toggle.tsx | Light/dark switch |
| currency-switcher.tsx | PYG/USD toggle |
| language-switcher.tsx | ES/EN/GN switch |
| page-transition.tsx | Page load animations |
| animations/ | Scroll-reveal, fade, slide animations |

#### Data Models
```
SQLite DB: data/viajero.db
Lib: db.ts (better-sqlite3)
Orders, products, users, subscribers, promos all in SQLite
Rate limiting: csrf.ts, api-auth.ts
i18n: i18n.ts (es/en/gn)
```

---

### 3b. Clinica Duerksen — Full Service Business (~40 components)

**Standalone site:** richest service-industry component library.

#### Page Sections (70+ routes)
```
Home (hero, about-preview, services-grid, reviews, instagram-feed, location)
Services (15+ dental service pages with details, pricing, before/after)
Blog (full blog system with categories)
Calculators (cost calculator, treatment comparison)
Patient forms (new patient, evaluation, smile assessment)
Appointment booking (agendar-cita with scheduling)
Gallery (before/after photos)
Reviews / Testimonials (resena)
Emergency dental (emergencia-dental)
Educational (educacion)
Patient resources (formulario-paciente, guia-primera-visita, pacientes-nerviosos)
Referral program (referidos)
Dental tourism (turismo-dental)
Promotions (promociones)
Nervous patients (pacientes-nerviosos)
En español (en/ subdirectory — bilingual)
```

#### Component Organization
```
components/
├── home/        hero, about-preview, services-grid, reviews, instagram-feed, location
├── layout/      header, footer, breadcrumb, cta-banner, newsletter-signup, whatsapp-button, cookie-consent
├── contact/     contact-form
├── gallery/     gallery-grid
├── seo/         json-ld, howto-json-ld
├── analytics/   google-analytics
└── ui/          accordion, badge, button, card, dialog, input, select, separator, sheet, textarea (Radix-based)
```

#### Backend
```
API routes: newsletter, contact, health, intake, appointment, testimonials, services
Server actions: contact.ts
Queries: submissions, services, testimonials, faq, blog
DB: Supabase (supabase.ts + @supabase/ssr)
Email: Resend (resend@10)
Forms: Server-side validation + rate limiting
Hooks: use-in-view (scroll detection)
```

#### Data Models
```
Supabase tables: submissions, testimonials, services, faq, blog
Types inferred from queries/queries/*.ts
Services data: lib/services-data.ts (static)
Blog data: lib/blog-data.ts (static)
Constants: lib/constants.ts
Validations: lib/validations.ts
```

---

### 3c. Fun4Me — Full Community Store (~50 components)

**Standalone site:** richest community/e-commerce hybrid.

#### Page Categories
```
Auth:         login, register, recover-password, age-gate
Store:        home, products, categories, product/[slug], cart, checkout, confirmation
Community:    calendario (events), cursos (courses), directorio (directory)
              grupos (groups), mensajes (messages), entradas (tickets)
              eventos/[slug]/confirmacion (event signup)
              kink/[slug] (kink pages)
Admin:        dashboard, products, categories, orders, coupons, events
              kinks, checkin, blacklist, announcements, verifications, ingresos
Profile:      /perfil/[id], /cuenta
Content:      blog, blog/[slug], blog/categoria/[category], nosotros, faq
              contacto, privacidad, terminos, envios, devoluciones, ofertas
              buscar (search), promociones, tienda, rss.xml
```

#### Standout Components (unique to fun4me)
```
age-gate.tsx           → age verification modal
privacy-mode-toggle.tsx → privacy/anonymity toggle
quick-exit.tsx         → panic button for sensitive content
safety-badges.tsx      → trust/safety indicators
sound-level.tsx        → content sensitivity indicator
level-badge.tsx        → user level/ranking badge
anon-review.tsx        → anonymous review/feedback
guest-mode.tsx         → guest browsing mode
privacy-faq.tsx        → privacy-specific FAQ
product-quiz.tsx       → product recommendation quiz
product-comparer.tsx   → side-by-side product compare
quick-order.tsx        → quick ordering form
shipping-calculator.tsx → shipping estimate
whatsapp-cart.tsx      → share cart via WhatsApp
membership-plans.tsx   → subscription/membership plans
social-proof.tsx       → social proof notifications
price-anchor.tsx       → anchor pricing display
payment-methods.tsx    → payment method icons
trust-badges.tsx       → trust badges section
announcement-bar.tsx   → top announcement bar
```

#### Admin Components
```
sidebar-nav.tsx, mobile-nav.tsx
product-form.tsx       → full product CRUD
category-form.tsx      → category CRUD
coupon-form.tsx        → coupon CRUD
kink-form.tsx          → kink CRUD
order-status-filter.tsx, order-status-update.tsx
anuncios-manager.tsx   → announcements CRUD
```

#### Backend
```
DB: PostgreSQL via pg@8
Auth: Custom bcryptjs+JWT (register/login/me/addresses)
API: /api/auth/*, /api/checkout, /api/orders, /api/profile
      /api/events, /api/newsletter, /api/check-blacklist
Cart: src/lib/store/cart.ts (client-side cart)
Lib: src/lib/vendor/wishlist.ts, recently-viewed.ts
     src/lib/utils/format.ts, whatsapp.ts
     src/lib/supabase/client.ts, server.ts
```

---

### 3d. Golden Visa Advisory — High-Conversion Landing (~7 components)

**Unique concepts:**
```
EntryModal.tsx          → language + path selection gate (7 languages)
LanguageDropdown.tsx    → inline language switcher
InvestorLanding.tsx     → full investor path with hero, team, process, comparison, CTA
BusinessLanding.tsx     → full business path with hero, what-is, services, chain-of-trust, CTA
ComparisonTable.tsx     → residency vs investment comparison
BusinessFAQ.tsx         → bilingual FAQ with 3 audience categories (devs, law firms, banks)
SuccessStory.tsx        → client success story block
```

**Content structure:**
```
1 master JSON: src/content/data.json
  → site (name, taglines in 3 languages)
  → programs (residency, SUACE, investor pass)
  → languages (7: en, es, pt, fr, de, it, ja — with flags)
  → per-locale: en.{entry, investor, business, faq}, es.{...}, etc.
```

---

## 4. Section Patterns (by Page Type)

These are the recurring page sections we can extract and reuse across clients.

### Home Page Sections
| Section | Available In | Reusable? |
|---------|-------------|-----------|
| Hero (image + headline + 2 CTAs) | ALL 15+ sites | ✅ Shared type |
| Stats/Counter strip | superspuma, dayah, depiflash, 3md, golden-visa | ✅ Template |
| Features/benefits grid | superspuma, dayah, depiflash, elviajero | ✅ Template |
| Services grid | superspuma, dayah, 3md, duerksen, magnolia, mantra | ✅ Template |
| Portfolio/works grid | dayah, ozmontania, 3md | ✅ Per client |
| Testimonials | superspuma, dayah, elviajero | ✅ Template |
| Process/steps section | superspuma, dayah, depiflash, golden-visa | ✅ Template |
| FAQ accordion | ALL sites | ✅ Template |
| Blog preview | elviajero, duerksen, superspuma, fun4me, ozmontania | ✅ Template |
| Newsletter signup | elviajero, duerksen | ✅ Template |
| Final CTA (last section) | ALL sites | ✅ Template |
| Location/map | duerksen, superspuma (tiendas) | ✅ Pattern |
| Instagram feed | duerksen | Needs API |
| Trust badges | fun4me, elviajero | ✅ Pattern |
| Social proof | fun4me, elviajero | ✅ Pattern |
| Exit intent | elviajero, fun4me | ✅ Pattern |
| Reading progress | elviajero | ✅ Pattern |
| Promo carousel | elviajero, fun4me | ✅ Pattern |
| Hero carousel | elviajero, fun4me | ✅ Pattern |
| Comparison table | golden-visa, duerksen | ✅ Pattern |

### Product/Service Pages
| Section | Available In | Reusable? |
|---------|-------------|-----------|
| Image gallery + magnifier | elviajero | ✅ Package |
| Product tabs | elviajero | ✅ Package |
| Product reviews | elviajero | ✅ Package |
| Product FAQ | elviajero | ✅ Package |
| Quick-view modal | elviajero | ✅ Package |
| Price display (PYG/USD) | elviajero, fun4me | ✅ Pattern |
| Delivery calculator | elviajero, fun4me | ✅ Pattern |
| Frequently bought together | elviajero | ✅ Package |
| Bundle builder | elviajero (bundle.ts) | ✅ Package |
| BOGO validator | elviajero | ✅ Package |
| Back-in-stock notify | elviajero | ✅ Package |

### E-Commerce
| Feature | Available In | Reusable? |
|---------|-------------|-----------|
| Cart (client-side) | elviajero, fun4me | ✅ Package |
| Cart sidebar/drawer | elviajero, fun4me | ✅ Pattern |
| Checkout stepper | elviajero, fun4me | ✅ Pattern |
| Coupon/promo codes | elviajero, fun4me | ✅ Package |
| Coupon input | elviajero, fun4me | ✅ Pattern |
| Order tracking | elviajero | ✅ |
| Order timeline | elviajero | ✅ |
| Recently viewed | elviajero, fun4me | ✅ Pattern |
| Wishlist | elviajero, fun4me | ✅ Pattern |
| Cart merger (guest→user) | elviajero | ✅ |
| Abandoned cart | elviajero | ✅ |
| Search autocomplete | elviajero, fun4me | ✅ Pattern |
| Search filters | elviajero | ✅ |
| Price range filter | elviajero | ✅ |
| Brand filter | elviajero | ✅ |
| Bulk pricing | elviajero | ✅ |
| Tax display | elviajero | ✅ |
| COD option | elviajero | ✅ |
| Pickup option | elviajero | ✅ |
| Shipping calculator | elviajero | ✅ |
| Paraguay address selector | elviajero | ✅ |

### Booking / Scheduling
| Feature | Available In | Reusable? |
|---------|-------------|-----------|
| Appointment booking | duerksen | ✅ |
| Calendar/events | fun4me | ✅ |
| Event confirmation | fun4me | ✅ |
| Course registration | fun4me | ✅ |

### Auth & User
| Feature | Available In | Reusable? |
|---------|-------------|-----------|
| Custom pg auth (JWT) | fun4me | ✅ Full system |
| SQLite auth + rate limit | elviajero | ✅ Pattern |
| Supabase auth + SSR | duerksen, fun4me | ✅ Pattern |
| Age gate | fun4me | ✅ |
| Guest mode | fun4me | ✅ |
| Privacy mode | fun4me | ✅ |
| Quick exit / panic | fun4me | ✅ |
| User profile | elviajero, fun4me | ✅ Pattern |
| Order history | elviajero, fun4me | ✅ Pattern |

### Admin Dashboards
| Feature | Available In | Reusable? |
|---------|-------------|-----------|
| Product CRUD | fun4me, elviajero | ✅ Pattern |
| Category management | fun4me | ✅ |
| Order management | fun4me, elviajero | ✅ Pattern |
| Order status updates | fun4me | ✅ |
| Coupon management | fun4me | ✅ |
| Event management | fun4me | ✅ |
| Blacklist management | fun4me | ✅ |
| Announcements | fun4me | ✅ |
| Checkin (attendance) | fun4me | ✅ |
| Verifications | fun4me | ✅ |
| User management | fun4me | ✅ |
| CSV export | elviajero | ✅ |
| PDF invoice | elviajero | ✅ |
| Stock history | elviajero | ✅ |

### SEO & Analytics
| Feature | Available In | Reusable? |
|---------|-------------|-----------|
| GA4 | duerksen, dayah, elviajero | ✅ Pattern |
| JSON-LD (org) | elviajero, duerksen, fun4me | ✅ Pattern |
| FAQ JSON-LD | elviajero, fun4me | ✅ Pattern |
| Article JSON-LD | elviajero, fun4me | ✅ Pattern |
| Breadcrumb JSON-LD | elviajero, fun4me | ✅ Pattern |
| HowTo JSON-LD | duerksen | ✅ |
| Sitemap (auto) | ALL Next.js sites | ✅ Framework |
| RSS feed | elviajero, fun4me, ozmontania | ✅ Pattern |
| Robots.txt | ALL sites | ✅ Framework |
| OG meta builder | elviajero | ✅ |
| Reading progress | elviajero | ✅ |

### Trust & Compliance
| Feature | Available In | Reusable? |
|---------|-------------|-----------|
| Cookie consent | 6+ sites | ✅ Shared component |
| Privacy policy | ALL sites | ✅ Static page |
| Terms & conditions | ALL sites | ✅ Static page |
| Safety badges | fun4me | ✅ |
| Content sensitivity | fun4me | ✅ |
| Rate limiting | elviajero, duerksen | ✅ Pattern |

---

## 5. Data Models Ready to Reuse

### Content Types (static sites)
```
NavigationItem, Navigation, HeroContent, StatItem, FeatureItem
ServiceItem, PortfolioItem, BookItem, ProcessStep, ProcessContent
Testimonial, FAQItem, FAQContent, WhatsAppContent, ContactInfo
ContactoContent, FooterLink, FooterColumn, FooterContent
FinalCta, Content (root), DeepPartial
```
**File:** `types/content.ts` — superspuma/dayah/depiflash

### Golden Visa Types
```
ContentData, LocalizedContent → entry, investor, business, faq
```
**File:** `src/content/types.ts`

### E-Commerce Models
```
PromoCode { code, type ("percentage"|"fixed"), value }
Review { id, productName, userName, rating }
ValidationResult { ok, errors }
Cart (in cart-context.tsx)
Order (in db.ts SQLite schema)
Product (in content/es.json productos array)
```
**Files:** elviajero: `lib/promo-codes.ts`, `lib/reviews.ts`, `lib/validation.ts`

### Fun4Me Models (PostgreSQL)
```
Tables via pg: users, products, orders, categories, coupons
                events, kinks, groups, messages, announcements
                blacklist, checkins, verifications
Auth: Custom JWT with bcryptjs, jose for JWTs
Cart: Client-side via src/lib/store/cart.ts
```
**Files:** fun4me: `src/lib/db.ts`, `src/lib/auth/*`

### Duerksen Models
```
Supabase tables: submissions, testimonials, services, faq, blog
Services: static data in lib/services-data.ts
Blog: static data in lib/blog-data.ts
Constants: lib/constants.ts
```

---

## 6. UI Library Components

### Radix UI Components (duerksen + fun4me)
```
Accordion, Dialog, Select, Separator, Sheet, Slot (Radix primitives)
Button, Card, Input, Textarea, Badge (shadcn-style wrappers)
Class Variance Authority (CVA) for variants
```

### Tailwind + lucide-react (ALL sites)
```
lucide-react icons (common across all)
tailwind-merge (cn() utility)
clsx (class merging)
Tailwind CSS 4 (latest across all sites)
```

### Fun4me Unique UI
```
Avatar, Checkbox, Drawer, Dropdown-menu, Label, Sonner (toast)
Switch, Table, Tabs — all custom-built
```

### Elviajero Unique UI
```
Custom: loading-bar, toast, tooltip, skeleton, page-transition
Animations: scroll-reveal, fade, slide
```

---

## 7. Ready-to-Extract Feature Modules

These are full feature modules that can be extracted into reusable packages:

| Module | Source | Lines | Dependencies |
|--------|--------|-------|-------------|
| WhatsApp Float | client-kit | ~30 | none |
| Cookie Consent | client-kit | ~50 | localStorage |
| Cart (context + sidebar) | elviajero | ~400 | React context |
| Checkout Stepper | elviajero | ~200 | React |
| Promo/BOGO Engine | elviajero | ~150 | none |
| Bundle Builder | elviajero | ~100 | none |
| Search Autocomplete | elviajero | ~200 | React |
| Auth (pg JWT) | fun4me | ~300 | pg, bcryptjs, jose |
| Auth (Supabase SSR) | duerksen | ~100 | supabase |
| Rate Limiter | elviajero | ~30 | Map |
| JSON-LD Generators | elviajero/fun4me | ~150 | none |
| Age Gate | fun4me | ~50 | React |
| Quick Exit / Panic | fun4me | ~30 | React |
| Product Quiz | fun4me | ~100 | React |
| Price Comparator | fun4me | ~80 | React |
| Recommendations Quiz | superspuma (needed) | — | — |
| Language Switcher (3+) | golden-visa/elviajero | ~50 | React |
| Entry Gate (path select) | golden-visa | ~80 | React |
| i18n System | elviajero/golden-visa | ~50 | none |
| Service Booking | duerksen | ~200 | Supabase |
| Contact Form + Rate Limit | duerksen | ~100 | Resend + validations |
| Abandoned Cart Recovery | elviajero | ~50 | localStorage |

---

## 8. Content i18n Systems Comparison

| System | Sites | Locales | Method |
|--------|-------|---------|--------|
| Static JSON | superspuma, dayah, depiflash, 3md, nudo, etc. | es only | Single es.json |
| Multi-file JSON | elviajero | es, en, gn | Separate files per locale |
| Multi-file JSON + GN | elviajero | es, en, gn | Includes Guaraní |
| Master JSON all locales | golden-visa | en, es, pt, fr, de, it, ja | 7 langs in 1 data.json |
| next-intl | duerksen | en, es | Framework-based |
| Manual context | golden-visa | 7 langs | Custom LocaleContext |

---

## 9. What We're Missing (Gaps)

| Feature | Need | Could Steal From |
|---------|------|-----------------|
| Real product images | superspuma, ozmontania | — |
| Bundle builder UI | superspuma (+Gs 1.17M upsell) | elviajero bundle.ts |
| Product finder quiz | superspuma | fun4me product-quiz.tsx |
| B2B portal | superspuma (2300 clients) | elviajero auth + admin |
| Cover naming system | dayah (239 unnamed) | — |
| Real artist images | ozmontania | — |
| Grafana dashboard | infra | — |
| NPM-published client-kit | all sites | /root/superspuma/lib/client-kit/ |
| Unified i18n package | all sites | golden-visa Pattern B |
| Booking system | any service client | duerksen |
| Newsletter system | any client | elviajero+duerksen |
| Abandoned cart | e-com clients | elviajero |
| Wishlist | e-com clients | elviajero+fun4me |
| Product reviews | any product site | elviajero |
| Order tracking | e-com clients | elviajero |
