// ============================================
// MONIFLY LANDING PAGE - JavaScript
// ============================================

document.addEventListener('DOMContentLoaded', () => {

    // ─── Mobile Menu ───────────────────────────
    const hamburger = document.getElementById('hamburger');
    const mobileMenu = document.getElementById('mobileMenu');
    const mobileLinks = document.querySelectorAll('.mobile-link');

    hamburger?.addEventListener('click', () => {
        hamburger.classList.toggle('open');
        mobileMenu.classList.toggle('open');
    });

    mobileLinks.forEach(link => {
        link.addEventListener('click', () => {
            hamburger.classList.remove('open');
            mobileMenu.classList.remove('open');
        });
    });

    document.addEventListener('click', (e) => {
        if (hamburger && mobileMenu &&
            !hamburger.contains(e.target) && !mobileMenu.contains(e.target)) {
            hamburger.classList.remove('open');
            mobileMenu.classList.remove('open');
        }
    });

    // ─── Header Scroll Effect ──────────────────
    const header = document.getElementById('header');

    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            header.classList.add('scrolled');
        } else {
            header.classList.remove('scrolled');
        }
    }, { passive: true });

    // ─── Smooth Scroll ─────────────────────────
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            if (href === '#') return;
            const target = document.querySelector(href);
            if (target) {
                e.preventDefault();
                const top = target.getBoundingClientRect().top + window.scrollY - (header ? header.offsetHeight : 72) - 16;
                window.scrollTo({ top, behavior: 'smooth' });
            }
        });
    });

    // ─── Scroll Reveal (single robust approach) ─
    // Collect all elements we want to animate
    const simpleReveal = document.querySelectorAll('[data-reveal], [data-reveal-delay]');
    const gridCards = document.querySelectorAll(
        '.audience-card, .feature-card, .testimonial-card, .step-card, .tool-item'
    );
    const miscReveal = document.querySelectorAll(
        '.pricing-card, .tools-block, .faq-list, .cta-box, .billing-toggle, .strategies-cta, .pricing-footer'
    );

    // Hide all initially via inline style (avoids CSS conflict)
    function hideEl(el, delay = 0) {
        el.style.opacity = '0';
        el.style.transform = 'translateY(28px)';
        el.style.transition = `opacity 0.65s ease ${delay}s, transform 0.65s ease ${delay}s`;
    }

    function showEl(el) {
        el.style.opacity = '1';
        el.style.transform = 'translateY(0)';
    }

    // Remove the CSS-based anonymity since we're using JS instead
    simpleReveal.forEach(el => hideEl(el));
    miscReveal.forEach(el => hideEl(el));
    gridCards.forEach((el, i) => {
        // Stagger siblings within same parent
        const siblings = Array.from(el.parentElement.children);
        const idx = siblings.indexOf(el);
        hideEl(el, idx * 0.08);
    });

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                showEl(entry.target);
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.08, rootMargin: '0px 0px 0px 0px' });

    [...simpleReveal, ...gridCards, ...miscReveal].forEach(el => observer.observe(el));

    // ─── FAQ Accordion ─────────────────────────
    document.querySelectorAll('.faq-item').forEach(item => {
        item.querySelector('.faq-question')?.addEventListener('click', () => {
            const isOpen = item.classList.contains('open');
            document.querySelectorAll('.faq-item').forEach(i => {
                i.classList.remove('open');
                i.querySelector('.faq-question')?.setAttribute('aria-expanded', 'false');
            });
            if (!isOpen) {
                item.classList.add('open');
                item.querySelector('.faq-question')?.setAttribute('aria-expanded', 'true');
            }
        });
    });

    // ─── Billing Toggle ────────────────────────
    const billingToggle = document.getElementById('billingToggle');
    const premiumPrice = document.getElementById('premiumPrice');
    const annualInfo = document.getElementById('annualInfo');
    let isAnnual = false;

    billingToggle?.addEventListener('click', () => {
        isAnnual = !isAnnual;
        billingToggle.classList.toggle('active', isAnnual);
        if (isAnnual) {
            if (premiumPrice) premiumPrice.textContent = 'R$ 7,49';
            if (annualInfo) annualInfo.style.display = 'block';
        } else {
            if (premiumPrice) premiumPrice.textContent = 'R$ 9,90';
            if (annualInfo) annualInfo.style.display = 'none';
        }
    });

    // ─── Sticky CTA ────────────────────────────
    const stickyCta = document.getElementById('stickyCta');
    const heroSection = document.getElementById('hero');

    if (heroSection && stickyCta) {
        new IntersectionObserver((entries) => {
            stickyCta.classList.toggle('visible', !entries[0].isIntersecting);
        }, { threshold: 0.2 }).observe(heroSection);
    }

    // ─── Social Proof Toasts Removed ───────────────────


    // ─── Active Nav Link ───────────────────────
    const navLinks = document.querySelectorAll('.nav-link');
    new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                navLinks.forEach(link => {
                    link.style.color = link.getAttribute('href') === `#${entry.target.id}`
                        ? 'var(--primary)' : '';
                });
            }
        });
    }, { threshold: 0.5 }).observe(document.querySelector('section[id]') || document.body);

    // ─── Parallax hero bg plane ────────────────
    const heroBgPlane = document.querySelector('.hero-bg-plane');
    window.addEventListener('scroll', () => {
        if (heroBgPlane) {
            heroBgPlane.style.transform = `translateY(${window.scrollY * 0.2}px) rotate(-10deg)`;
        }
    }, { passive: true });

    // ─── Pricing card mouse glow ───────────────
    document.querySelectorAll('.pricing-card').forEach(card => {
        card.addEventListener('mousemove', (e) => {
            const r = card.getBoundingClientRect();
            const x = ((e.clientX - r.left) / r.width) * 100;
            const y = ((e.clientY - r.top) / r.height) * 100;
            card.style.background = `radial-gradient(circle at ${x}% ${y}%, rgba(14,165,233,0.05) 0%, white 60%)`;
        });
        card.addEventListener('mouseleave', () => { card.style.background = ''; });
    });

});
