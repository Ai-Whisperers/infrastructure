import { createMockWorkItem } from '../utils/test-factories'

export class MockAzureDevOpsAPI {
  private workItems = new Map<number, any>()
  private nextWorkItemId = 1000
  private organizationUrl: string

  constructor(org: string = 'test-org', project: string = 'test-project') {
    this.organizationUrl = `https://dev.azure.com/${org}`

    // Initialize with mock work items
    for (let i = 0; i < 20; i++) {
      const workItem = createMockWorkItem({ id: this.nextWorkItemId++ })
      this.workItems.set(workItem.id, workItem)
    }
  }

  async getWorkItem(id: number, expand?: string) {
    const workItem = this.workItems.get(id)
    if (!workItem) {
      throw { status: 404, message: `Work Item ${id} does not exist.` }
    }

    const result = { ...workItem }

    if (expand?.includes('relations')) {
      result.relations = [
        {
          rel: 'System.LinkTypes.Hierarchy-Forward',
          url: `${this.organizationUrl}/_apis/wit/workItems/${id + 1}`,
          attributes: { name: 'Child' }
        }
      ]
    }

    return workItem
  }

  async getWorkItems(ids: number[], expand?: string) {
    const results = ids.map(id => {
      const workItem = this.workItems.get(id)
      if (!workItem) {
        return { id, error: 'Not found' }
      }
      return workItem
    })

    return { value: results.filter(r => !r.error) }
  }

  async createWorkItem(project: string, type: string, document: any[]) {
    const workItem = createMockWorkItem({
      id: this.nextWorkItemId++,
      type,
      fields: this.parseDocument(document)
    })

    this.workItems.set(workItem.id, workItem)
    return workItem
  }

  async updateWorkItem(id: number, document: any[]) {
    const workItem = this.workItems.get(id)
    if (!workItem) {
      throw { status: 404, message: `Work Item ${id} does not exist.` }
    }

    const updates = this.parseDocument(document)
    Object.assign(workItem.fields, updates)
    workItem.rev++
    workItem.fields['System.ChangedDate'] = new Date().toISOString()

    return workItem
  }

  async queryWorkItems(wiql: string, top?: number) {
    // Simple mock query - return random work items
    const allIds = Array.from(this.workItems.keys())
    const selectedIds = allIds.slice(0, Math.min(top || 50, allIds.length))

    return {
      workItems: selectedIds.map(id => ({ id, url: `${this.organizationUrl}/_apis/wit/workItems/${id}` })),
      asOf: new Date().toISOString(),
      columns: [],
      sortColumns: []
    }
  }

  async addWorkItemRelation(id: number, relation: any) {
    const workItem = this.workItems.get(id)
    if (!workItem) {
      throw { status: 404, message: `Work Item ${id} does not exist.` }
    }

    if (!workItem.relations) {
      workItem.relations = []
    }

    workItem.relations.push({
      rel: relation.rel || 'System.LinkTypes.Related',
      url: relation.url,
      attributes: relation.attributes || {}
    })

    return workItem
  }

  async removeWorkItemRelation(id: number, index: number) {
    const workItem = this.workItems.get(id)
    if (!workItem) {
      throw { status: 404, message: `Work Item ${id} does not exist.` }
    }

    if (workItem.relations && workItem.relations[index]) {
      workItem.relations.splice(index, 1)
    }

    return workItem
  }

  async getWorkItemTypes(project: string) {
    return {
      value: [
        { name: 'Bug', icon: '🐛', color: 'CC293D' },
        { name: 'Task', icon: '📋', color: 'F2CB1D' },
        { name: 'Feature', icon: '✨', color: '009CCC' },
        { name: 'Epic', icon: '🎯', color: '773B93' },
        { name: 'User Story', icon: '📖', color: '009CCC' }
      ]
    }
  }

  async getIterations(project: string) {
    return {
      value: [
        {
          id: '1',
          name: 'Sprint 1',
          path: '\\Project\\Iteration\\Sprint 1',
          attributes: {
            startDate: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString(),
            finishDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString()
          }
        },
        {
          id: '2',
          name: 'Sprint 2',
          path: '\\Project\\Iteration\\Sprint 2',
          attributes: {
            startDate: new Date().toISOString(),
            finishDate: new Date(Date.now() + 13 * 24 * 60 * 60 * 1000).toISOString()
          }
        }
      ]
    }
  }

  // Utility methods for testing
  addWorkItem(workItem: any) {
    this.workItems.set(workItem.id, workItem)
  }

  clearWorkItems() {
    this.workItems.clear()
  }

  getWorkItemCount() {
    return this.workItems.size
  }

  private parseDocument(document: any[]) {
    const fields: any = {}

    for (const op of document) {
      if (op.op === 'add' && op.path.startsWith('/fields/')) {
        const fieldName = op.path.replace('/fields/', '')
        fields[fieldName] = op.value
      }
    }

    return fields
  }
}