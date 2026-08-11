/**
 * AI Image to Invoice Converter & Editor
 * Frontend application logic
 */

// Sample Invoice Data
const SAMPLE_DATA = {
    coffee: {
        vendorName: "Artisan Brew Cafe",
        vendorAddress: "123 Coffee Lane, Seattle, WA 98101\ncontact@artisanbrew.com\n+1 (206) 555-0192",
        invoiceTitle: "RECEIPT",
        invoiceNumber: "ABC-2026-089",
        date: "2026-07-29",
        dueDate: "2026-07-29",
        clientName: "John Doe",
        clientAddress: "Freelance Designer\njohn.doe@example.com\nSeattle, WA",
        taxRate: 8.5,
        discount: 2.00,
        notes: "Thank you for stopping by! Payment received via Credit Card. \nOrder: #8794-A.",
        items: [
            { desc: "Caramel Macchiato (Large)", qty: 2, price: 5.50 },
            { desc: "Artisan Avocado Toast", qty: 1, price: 12.00 },
            { desc: "Blueberry Crumble Muffin", qty: 3, price: 3.75 }
        ]
    },
    tech: {
        vendorName: "NextGen Electronics Ltd",
        vendorAddress: "786 Innovation Way, Tech Park, Austin, TX 78701\nsales@nextgenelectronics.com\n+1 (512) 555-0343",
        invoiceTitle: "INVOICE",
        invoiceNumber: "NGE-98741",
        date: "2026-07-28",
        dueDate: "2026-08-28",
        clientName: "Acme Corporation",
        clientAddress: "Attn: Procurement Dept\n100 Enterprise Blvd, Suite 400\nAustin, TX 78744\nbilling@acme.com",
        taxRate: 12.0,
        discount: 50.00,
        notes: "Payment due within 30 days of invoice date. Bank transfer info:\nChase Bank, SWIFT: CHASEUS33, Acc: 1234-5678-9012.",
        items: [
            { desc: 'UltraWide HDR Monitor 34"', qty: 2, price: 449.99 },
            { desc: "Ergonomic Mechanical Keyboard (RGB)", qty: 5, price: 129.50 },
            { desc: "USB-C Multi-Port Docking Adapter", qty: 10, price: 35.00 }
        ]
    },
    grocery: {
        vendorName: "Organic Foods Supermarket",
        vendorAddress: "99 Green Avenue, Portland, OR 97201\nsupport@organicfoods.co\n+1 (503) 555-8833",
        invoiceTitle: "SALES RECEIPT",
        invoiceNumber: "ORG-44021",
        date: "2026-07-29",
        dueDate: "2026-07-29",
        clientName: "Sarah Jenkins",
        clientAddress: "Loyalty Premium Member\nCard Ending: *4829\nsarah.jenkins@mail.com",
        taxRate: 5.0,
        discount: 5.00,
        notes: "Thank you for buying organic and supporting local farms! \nYour loyalty program points added: 124 pts.",
        items: [
            { desc: "Organic Bananas Bunch", qty: 2, price: 3.49 },
            { desc: "Fresh Sweet Strawberries 1lb", qty: 3, price: 4.99 },
            { desc: "Unsweetened Almond Milk 1L", qty: 4, price: 2.89 },
            { desc: "Artisanal Whole Wheat Bread", qty: 2, price: 3.99 },
            { desc: "Grass-Fed Ribeye Steak (USDA Prime)", qty: 2, price: 18.99 }
        ]
    }
};

// Generic mock data for user uploaded files
const GENERIC_UPLOAD_DATA = {
    vendorName: "AI Scanner Extracted Inc.",
    vendorAddress: "100 AI Highway, Silicon Valley, CA\ninfo@aiscannerextracted.com",
    invoiceTitle: "INVOICE",
    invoiceNumber: "EXT-88921",
    date: new Date().toISOString().split('T')[0],
    dueDate: new Date(Date.now() + 14 * 86400000).toISOString().split('T')[0], // 14 days later
    clientName: "Valued Customer",
    clientAddress: "Please verify and edit this address details.",
    taxRate: 10.0,
    discount: 0.00,
    notes: "Review AI-extracted fields carefully. Edit anything that requires corrections.",
    items: [
        { desc: "Extracted Item A (Verify description)", qty: 1, price: 79.99 },
        { desc: "Extracted Item B (Verify quantity)", qty: 2, price: 15.50 },
        { desc: "Extracted Item C (Verify price)", qty: 3, price: 9.00 }
    ]
};

// DOM Elements
const dropZone = document.getElementById('drop-zone');
const fileInput = document.getElementById('file-input');
const uploadPrompt = document.getElementById('upload-prompt');
const previewContainer = document.getElementById('preview-container');
const imagePreview = document.getElementById('image-preview');
const removeImgBtn = document.getElementById('remove-img-btn');
const processingOverlay = document.getElementById('processing-overlay');

const vendorNameInput = document.getElementById('vendor-name');
const vendorAddressInput = document.getElementById('vendor-address');
const invoiceTitleInput = document.getElementById('invoice-title');
const invoiceNumberInput = document.getElementById('invoice-number');
const invoiceDateInput = document.getElementById('invoice-date');
const invoiceDueDateInput = document.getElementById('invoice-due-date');
const clientNameInput = document.getElementById('client-name');
const clientAddressInput = document.getElementById('client-address');
const itemsTbody = document.getElementById('items-tbody');
const addItemBtn = document.getElementById('add-item-btn');
const invoiceNotesInput = document.getElementById('invoice-notes');

const taxRateInput = document.getElementById('tax-rate');
const discountAmountInput = document.getElementById('discount-amount');

const valSubtotal = document.getElementById('val-subtotal');
const valTax = document.getElementById('val-tax');
const valTotal = document.getElementById('val-total');

const resetBtn = document.getElementById('reset-btn');
const exportJsonBtn = document.getElementById('export-json-btn');
const printBtn = document.getElementById('print-btn');

// Initialize App
document.addEventListener('DOMContentLoaded', () => {
    setupEventListeners();
    // Load a default empty invoice state
    resetInvoice();
});

function setupEventListeners() {
    // File Upload / Drag & Drop
    dropZone.addEventListener('click', () => fileInput.click());
    
    fileInput.addEventListener('change', (e) => {
        if (e.target.files.length > 0) {
            handleFile(e.target.files[0]);
        }
    });

    dropZone.addEventListener('dragover', (e) => {
        e.preventDefault();
        dropZone.classList.add('dragover');
    });

    ['dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, () => {
            dropZone.classList.remove('dragover');
        });
    });

    dropZone.addEventListener('drop', (e) => {
        e.preventDefault();
        if (e.dataTransfer.files.length > 0) {
            handleFile(e.dataTransfer.files[0]);
        }
    });

    removeImgBtn.addEventListener('click', (e) => {
        e.stopPropagation(); // Avoid triggering file chooser
        clearImage();
    });

    // Sample Invoice Buttons
    document.querySelectorAll('.btn-sample').forEach(button => {
        button.addEventListener('click', (e) => {
            e.stopPropagation();
            const sampleKey = button.getAttribute('data-sample');
            loadSample(sampleKey);
        });
    });

    // Invoice Action Buttons
    resetBtn.addEventListener('click', resetInvoice);
    printBtn.addEventListener('click', () => window.print());
    exportJsonBtn.addEventListener('click', exportToJSON);

    // Add Item Event
    addItemBtn.addEventListener('click', () => {
        createItemRow("", 1, 0.00);
        calculateInvoice();
    });

    // Summary inputs trigger recalculation
    taxRateInput.addEventListener('input', calculateInvoice);
    discountAmountInput.addEventListener('input', calculateInvoice);
}

// Handle File upload
function handleFile(file) {
    if (!file.type.startsWith('image/')) {
        alert('Please upload an image file (PNG, JPG, JPEG, WEBP).');
        return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
        // Show image preview
        imagePreview.src = e.target.result;
        uploadPrompt.classList.add('hidden');
        previewContainer.classList.remove('hidden');
        previewContainer.classList.add('scanning');
        processingOverlay.classList.remove('hidden');

        // Simulate AI OCR processing
        setTimeout(() => {
            previewContainer.classList.remove('scanning');
            processingOverlay.classList.add('hidden');
            
            // Populate form with generic/simulated OCR output
            populateInvoiceForm(GENERIC_UPLOAD_DATA);
        }, 1800);
    };
    reader.readAsDataURL(file);
}

// Clear Image Preview
function clearImage() {
    fileInput.value = '';
    imagePreview.src = '';
    previewContainer.classList.add('hidden');
    uploadPrompt.classList.remove('hidden');
}

// Load a specific pre-defined sample receipt
function loadSample(key) {
    const data = SAMPLE_DATA[key];
    if (!data) return;

    // Simulate OCR scanning loader
    previewContainer.classList.remove('hidden');
    uploadPrompt.classList.add('hidden');
    previewContainer.classList.add('scanning');
    processingOverlay.classList.remove('hidden');
    
    // Set a matching mock image depending on sample
    imagePreview.src = getPlaceholderImageUrl(key);

    setTimeout(() => {
        previewContainer.classList.remove('scanning');
        processingOverlay.classList.add('hidden');
        populateInvoiceForm(data);
    }, 1500);
}

// Mock URLs for the samples using CSS SVG Data URL instead of external images to be robust offline
function getPlaceholderImageUrl(key) {
    // Generate inline SVG placeholder images representing receipts
    const svgMap = {
        coffee: `<svg xmlns="http://www.w3.org/2000/svg" width="300" height="400" viewBox="0 0 300 400" style="background:#f4ece1;font-family:monospace;padding:20px;box-sizing:border-box;">
            <text x="50%" y="40" dominant-baseline="middle" text-anchor="middle" font-size="20" font-weight="bold" fill="#4a3b32">ARTISAN BREW CAFE</text>
            <text x="50%" y="60" text-anchor="middle" font-size="10" fill="#666">123 Coffee Lane, Seattle</text>
            <text x="10" y="100" font-size="12">Receipt: ABC-2026-089</text>
            <text x="10" y="120" font-size="12">Date: 2026-07-29</text>
            <text x="10" y="150" font-size="12">----------------------------------</text>
            <text x="10" y="170" font-size="12">2x Caramel Macchiato       11.00</text>
            <text x="10" y="190" font-size="12">1x Artisan Avocado Toast   12.00</text>
            <text x="10" y="210" font-size="12">3x Blueberry Muffin        11.25</text>
            <text x="10" y="240" font-size="12">----------------------------------</text>
            <text x="10" y="260" font-size="12">SUBTOTAL                   34.25</text>
            <text x="10" y="280" font-size="12">TAX (8.5%)                  2.91</text>
            <text x="10" y="300" font-size="12">DISCOUNT                    2.00</text>
            <text x="10" y="320" font-size="14" font-weight="bold">TOTAL                      $35.16</text>
            <text x="50%" y="370" text-anchor="middle" font-size="12" fill="#4a3b32">Thank you!</text>
        </svg>`,
        tech: `<svg xmlns="http://www.w3.org/2000/svg" width="300" height="400" viewBox="0 0 300 400" style="background:#eef2f6;font-family:sans-serif;padding:20px;box-sizing:border-box;">
            <text x="20" y="40" font-size="18" font-weight="bold" fill="#1e3a8a">NEXTGEN ELECTRONICS</text>
            <text x="20" y="80" font-size="11" fill="#475569">Invoice No: NGE-98741</text>
            <text x="20" y="95" font-size="11" fill="#475569">Date: 2026-07-28</text>
            <path d="M 20 120 L 280 120" stroke="#cbd5e1" stroke-width="1"/>
            <text x="20" y="140" font-size="11" font-weight="bold">ITEMS</text>
            <text x="20" y="165" font-size="10">2x UltraWide Monitor 34"  899.98</text>
            <text x="20" y="185" font-size="10">5x Mech Keyboard          647.50</text>
            <text x="20" y="205" font-size="10">10x USB-C Adapter         350.00</text>
            <path d="M 20 225 L 280 225" stroke="#cbd5e1" stroke-width="1"/>
            <text x="150" y="250" font-size="11">Subtotal:</text> <text x="240" y="250" font-size="11">1,897.48</text>
            <text x="150" y="270" font-size="11">Tax (12%):</text> <text x="240" y="270" font-size="11">227.70</text>
            <text x="150" y="290" font-size="11">Discount:</text> <text x="240" y="290" font-size="11">50.00</text>
            <text x="150" y="320" font-size="13" font-weight="bold" fill="#1e3a8a">Total:</text> <text x="240" y="320" font-size="13" font-weight="bold" fill="#1e3a8a">$2,075.18</text>
        </svg>`,
        grocery: `<svg xmlns="http://www.w3.org/2000/svg" width="300" height="400" viewBox="0 0 300 400" style="background:#f0fdf4;font-family:monospace;padding:15px;box-sizing:border-box;">
            <text x="50%" y="30" text-anchor="middle" font-size="18" font-weight="bold" fill="#166534">ORGANIC FOODS</text>
            <text x="50%" y="48" text-anchor="middle" font-size="9" fill="#15803d">99 Green Ave, Portland</text>
            <text x="10" y="90" font-size="11">Receipt: ORG-44021</text>
            <text x="10" y="105" font-size="11">Date: 2026-07-29</text>
            <text x="10" y="125" font-size="11">================================</text>
            <text x="10" y="145" font-size="11">2x Org Bananas Bunch        6.98</text>
            <text x="10" y="165" font-size="11">3x Strawberry 1lb          14.97</text>
            <text x="10" y="185" font-size="11">4x Almond Milk 1L          11.56</text>
            <text x="10" y="205" font-size="11">2x Whole Wheat Bread        7.98</text>
            <text x="10" y="225" font-size="11">2x Ribeye Steak            37.98</text>
            <text x="10" y="245" font-size="11">================================</text>
            <text x="120" y="270" font-size="11">SUBTOTAL:</text> <text x="220" y="270" font-size="11">79.47</text>
            <text x="120" y="285" font-size="11">TAX (5.0%):</text> <text x="220" y="285" font-size="11">3.97</text>
            <text x="120" y="300" font-size="11">DISCOUNT:</text> <text x="220" y="300" font-size="11">5.00</text>
            <text x="120" y="325" font-size="13" font-weight="bold">TOTAL:</text> <text x="220" y="325" font-size="13" font-weight="bold">$78.44</text>
        </svg>`
    };
    const svgContent = svgMap[key] || '';
    return `data:image/svg+xml;utf8,${encodeURIComponent(svgContent)}`;
}

// Populate the Invoice Form Fields
function populateInvoiceForm(data) {
    vendorNameInput.value = data.vendorName || '';
    vendorAddressInput.value = data.vendorAddress || '';
    invoiceTitleInput.value = data.invoiceTitle || 'INVOICE';
    invoiceNumberInput.value = data.invoiceNumber || '';
    invoiceDateInput.value = data.date || '';
    invoiceDueDateInput.value = data.dueDate || '';
    clientNameInput.value = data.clientName || '';
    clientAddressInput.value = data.clientAddress || '';
    
    taxRateInput.value = data.taxRate !== undefined ? data.taxRate : 10;
    discountAmountInput.value = data.discount !== undefined ? data.discount.toFixed(2) : '0.00';
    invoiceNotesInput.value = data.notes || '';

    // Clear items table body
    itemsTbody.innerHTML = '';

    // Add new items
    if (data.items && data.items.length > 0) {
        data.items.forEach(item => {
            createItemRow(item.desc, item.qty, item.price);
        });
    } else {
        createItemRow("", 1, 0.00);
    }

    calculateInvoice();
}

// Create an Item Row in the table
function createItemRow(desc = "", qty = 1, price = 0.00) {
    const tr = document.createElement('tr');
    
    tr.innerHTML = `
        <td class="col-desc">
            <input type="text" class="invoice-input item-desc-input" placeholder="Item Name / Description" value="${desc}">
        </td>
        <td class="col-qty">
            <input type="number" class="invoice-input item-qty-input" min="1" step="1" value="${qty}">
        </td>
        <td class="col-price">
            <input type="number" class="invoice-input item-price-input" min="0" step="0.01" value="${price.toFixed(2)}">
        </td>
        <td class="col-total">$0.00</td>
        <td class="col-actions no-print">
            <button class="btn-delete-row" title="Delete item">
                <i class="fa-solid fa-trash"></i>
            </button>
        </td>
    `;

    // Listeners for inputs on this row
    const qtyInput = tr.querySelector('.item-qty-input');
    const priceInput = tr.querySelector('.item-price-input');
    const descInput = tr.querySelector('.item-desc-input');
    const deleteBtn = tr.querySelector('.btn-delete-row');

    [qtyInput, priceInput, descInput].forEach(input => {
        input.addEventListener('input', () => {
            calculateInvoice();
        });
    });

    deleteBtn.addEventListener('click', () => {
        tr.remove();
        // Keep at least one row
        if (itemsTbody.children.length === 0) {
            createItemRow("", 1, 0.00);
        }
        calculateInvoice();
    });

    itemsTbody.appendChild(tr);
}

// Calculate entire Invoice totals
function calculateInvoice() {
    let subtotal = 0;
    const rows = itemsTbody.querySelectorAll('tr');

    rows.forEach(row => {
        const qtyInput = row.querySelector('.item-qty-input');
        const priceInput = row.querySelector('.item-price-input');
        const totalCell = row.querySelector('.col-total');

        const qty = parseInt(qtyInput.value) || 0;
        const price = parseFloat(priceInput.value) || 0.00;
        
        const rowTotal = qty * price;
        subtotal += rowTotal;

        totalCell.textContent = `$${rowTotal.toFixed(2)}`;
    });

    // Read tax rate and discount
    const taxRate = parseFloat(taxRateInput.value) || 0;
    const discount = parseFloat(discountAmountInput.value) || 0;

    // Calculation calculations
    const taxAmount = subtotal * (taxRate / 100);
    const grandTotal = Math.max(0, subtotal + taxAmount - discount);

    // Update displays
    valSubtotal.textContent = `$${subtotal.toFixed(2)}`;
    valTax.textContent = `$${taxAmount.toFixed(2)}`;
    valTotal.textContent = `$${grandTotal.toFixed(2)}`;
}

// Reset Invoice to base empty state
function resetInvoice() {
    clearImage();
    
    vendorNameInput.value = '';
    vendorAddressInput.value = '';
    invoiceTitleInput.value = 'INVOICE';
    invoiceNumberInput.value = '';
    
    // Set current date
    const today = new Date().toISOString().split('T')[0];
    invoiceDateInput.value = today;
    invoiceDueDateInput.value = today;

    clientNameInput.value = '';
    clientAddressInput.value = '';
    taxRateInput.value = 10;
    discountAmountInput.value = '0.00';
    invoiceNotesInput.value = '';

    itemsTbody.innerHTML = '';
    createItemRow("", 1, 0.00);
    calculateInvoice();
}

// Export Invoice Details as JSON
function exportToJSON() {
    const items = [];
    const rows = itemsTbody.querySelectorAll('tr');
    
    rows.forEach(row => {
        const desc = row.querySelector('.item-desc-input').value;
        const qty = parseInt(row.querySelector('.item-qty-input').value) || 0;
        const price = parseFloat(row.querySelector('.item-price-input').value) || 0;
        
        items.push({
            description: desc,
            quantity: qty,
            unitPrice: price,
            totalPrice: qty * price
        });
    });

    const subtotalText = valSubtotal.textContent.replace('$', '');
    const taxText = valTax.textContent.replace('$', '');
    const totalText = valTotal.textContent.replace('$', '');

    const invoiceData = {
        vendor: {
            name: vendorNameInput.value,
            address: vendorAddressInput.value
        },
        metadata: {
            title: invoiceTitleInput.value,
            invoiceNumber: invoiceNumberInput.value,
            date: invoiceDateInput.value,
            dueDate: invoiceDueDateInput.value
        },
        client: {
            name: clientNameInput.value,
            address: clientAddressInput.value
        },
        items: items,
        summary: {
            subtotal: parseFloat(subtotalText),
            taxRate: parseFloat(taxRateInput.value) || 0,
            taxAmount: parseFloat(taxText),
            discount: parseFloat(discountAmountInput.value) || 0,
            grandTotal: parseFloat(totalText)
        },
        notes: invoiceNotesInput.value
    };

    // Download file
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(invoiceData, null, 2));
    const downloadAnchor = document.createElement('a');
    const filename = `invoice_${invoiceNumberInput.value || 'draft'}.json`;
    
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute("download", filename);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
}
