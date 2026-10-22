'use strict';

const machinesEl = document.getElementById('machines');
const searchEl = document.getElementById('search');
const categoryEl = document.getElementById('category');
const dialog = document.getElementById('machineDialog');
const form = document.getElementById('machineForm');

async function api(path, options) {
  const response = await fetch(path, options);
  if (!response.ok) throw new Error(`Request failed: ${response.status}`);
  return response.json();
}

function bar(value, total) {
  if (!total) return '<div class="bar"><span style="width:0%"></span></div>';
  const percent = Math.max(0, Math.min(100, (value / total) * 100));
  return `<div class="bar"><span style="width:${percent}%"></span></div>`;
}

function machineCard(machine) {
  const tags = machine.tags.map(tag => `<span class="tag">${tag}</span>`).join('');
  const link = machine.url
    ? `<a class="button" href="${machine.url}" target="_blank" rel="noopener">Open</a>`
    : '';

  return `
    <article class="card status-${machine.status}">
      <header>
        <h3>${machine.hostname}</h3>
        <span class="dot"></span>
      </header>
      <p class="meta">VMID ${machine.vmid} • ${machine.ip || 'No IP'} • ${machine.node || 'Unknown node'}</p>
      <div class="metrics">
        <div>CPU ${machine.cpu || 0}%</div>
        <div>RAM ${machine.memoryUsed || 0} / ${machine.memoryTotal || 0} GB</div>
        <div>Disk ${machine.diskUsed || 0} / ${machine.diskTotal || 0} GB</div>
      </div>
      ${bar(machine.memoryUsed, machine.memoryTotal)}
      <div class="tags">${tags}</div>
      <footer>${link}<button class="button edit" data-vmid="${machine.vmid}">Edit</button></footer>
    </article>
  `;
}

function render(machines) {
  const query = searchEl.value.toLowerCase();
  const category = categoryEl.value;

  const visible = machines.filter(machine => {
    const matchesCategory = category === 'all' || machine.category === category;
    const haystack = [
      machine.hostname, machine.ip, machine.node, machine.category,
      machine.vmid, ...machine.tags
    ].join(' ').toLowerCase();
    return matchesCategory && haystack.includes(query);
  });

  machinesEl.innerHTML = visible.length
    ? visible.map(machineCard).join('')
    : '<p class="empty">No machines yet. Use “Add machine” to create your first entry.</p>';
}

async function refresh() {
  try {
    const [machines, config] = await Promise.all([
      api('/api/machines'),
      api('/api/config')
    ]);
    render(machines);
    const status = document.getElementById('status');
    status.textContent = config.proxmoxConfigured && config.truenasConfigured
      ? 'APIs configured'
      : 'Add API credentials';
    status.className = `pill ${config.proxmoxConfigured && config.truenasConfigured ? 'ok' : 'warn'}`;
  } catch (error) {
    document.getElementById('status').textContent = 'Offline';
    document.getElementById('status').className = 'pill error';
  }
}

form.addEventListener('submit', async event => {
  event.preventDefault();
  const data = Object.fromEntries(new FormData(form));
  data.tags = data.tags.split(',').map(tag => tag.trim()).filter(Boolean);
  data.vmid = String(data.vmid);
  await api('/api/machines', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
  dialog.close();
  form.reset();
  refresh();
});

document.getElementById('addMachine').addEventListener('click', () => dialog.showModal());
searchEl.addEventListener('input', refresh);
categoryEl.addEventListener('change', refresh);

machinesEl.addEventListener('click', event => {
  const button = event.target.closest('.edit');
  if (!button) return;
  const vmid = button.dataset.vmid;
  api('/api/machines').then(machines => {
    const machine = machines.find(item => String(item.vmid) === vmid);
    if (!machine) return;
    Object.entries(machine).forEach(([key, value]) => {
      if (form.elements[key]) form.elements[key].value = Array.isArray(value) ? value.join(',') : value;
    });
    dialog.showModal();
  });
});

refresh();
setInterval(refresh, 15000);
