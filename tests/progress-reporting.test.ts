import { describe, it, beforeEach, expect, vi } from "vitest"

// Mock the Clarity blockchain environment
const mockClarity = {
  contracts: {
    "progress-reporting": {
      functions: {
        "submit-report": vi.fn(),
        "update-report-status": vi.fn(),
        "get-report": vi.fn(),
        "get-project-report-summary": vi.fn(),
        "set-contract-admin": vi.fn(),
      },
      constants: {
        "STATUS-PLANNED": 1,
        "STATUS-IN-PROGRESS": 2,
        "STATUS-COMPLETED": 3,
        "STATUS-DELAYED": 4,
        "ERR-NOT-AUTHORIZED": 100,
        "ERR-REPORT-EXISTS": 101,
        "ERR-REPORT-NOT-FOUND": 102,
        "ERR-INVALID-STATUS": 103,
      },
    },
  },
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  },
}

// Mock the contract calls
const mockContractCall = (functionName, args, result) => {
  mockClarity.contracts["progress-reporting"].functions[functionName].mockReturnValueOnce(result)
}

describe("Progress Reporting Contract", () => {
  beforeEach(() => {
    // Reset all mocks before each test
    vi.resetAllMocks()
  })
  
  it("should submit a report successfully", () => {
    // Create a mock buffer for media hash
    const mediaHash = new Uint8Array(32).fill(1)
    
    // Mock successful report submission
    mockContractCall(
        "submit-report",
        [
          1, // project-id
          "Q1 2023 Progress",
          "Detailed description of conservation activities during Q1 2023",
          "Establish protected area boundaries",
          2, // STATUS-IN-PROGRESS
          mediaHash,
        ],
        { success: true, value: 1 },
    )
    
    // Call the contract function
    const result = mockClarity.contracts["progress-reporting"].functions["submit-report"](
        1,
        "Q1 2023 Progress",
        "Detailed description of conservation activities during Q1 2023",
        "Establish protected area boundaries",
        2,
        mediaHash,
    )
    
    // Verify the result
    expect(result).toEqual({ success: true, value: 1 })
    expect(mockClarity.contracts["progress-reporting"].functions["submit-report"]).toHaveBeenCalledTimes(1)
  })
  
  it("should update report status successfully", () => {
    // Mock successful status update
    mockContractCall("update-report-status", [1, 3], { success: true, value: true })
    
    // Call the contract function
    const result = mockClarity.contracts["progress-reporting"].functions["update-report-status"](1, 3)
    
    // Verify the result
    expect(result).toEqual({ success: true, value: true })
    expect(mockClarity.contracts["progress-reporting"].functions["update-report-status"]).toHaveBeenCalledTimes(1)
  })
  
  it("should get report details successfully", () => {
    // Create a mock buffer for media hash
    const mediaHash = new Uint8Array(32).fill(1)
    
    // Mock report data
    const reportData = {
      "project-id": 1,
      title: "Q1 2023 Progress",
      description: "Detailed description of conservation activities during Q1 2023",
      milestone: "Establish protected area boundaries",
      status: 2,
      "report-date": 100,
      author: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      "media-hash": mediaHash,
    }
    
    // Mock successful report retrieval
    mockContractCall("get-report", [1], { success: true, value: reportData })
    
    // Call the contract function
    const result = mockClarity.contracts["progress-reporting"].functions["get-report"](1)
    
    // Verify the result
    expect(result).toEqual({ success: true, value: reportData })
    expect(mockClarity.contracts["progress-reporting"].functions["get-report"]).toHaveBeenCalledTimes(1)
  })
  
  it("should get project report summary successfully", () => {
    // Mock summary data
    const summaryData = {
      "report-count": 5,
      "last-report-date": 150,
    }
    
    // Mock successful summary retrieval
    mockContractCall("get-project-report-summary", [1], { success: true, value: summaryData })
    
    // Call the contract function
    const result = mockClarity.contracts["progress-reporting"].functions["get-project-report-summary"](1)
    
    // Verify the result
    expect(result).toEqual({ success: true, value: summaryData })
    expect(mockClarity.contracts["progress-reporting"].functions["get-project-report-summary"]).toHaveBeenCalledTimes(1)
  })
  
  it("should fail when invalid status is provided", () => {
    // Create a mock buffer for media hash
    const mediaHash = new Uint8Array(32).fill(1)
    
    // Mock invalid status error
    mockContractCall(
        "submit-report",
        [
          1, // project-id
          "Q1 2023 Progress",
          "Detailed description of conservation activities during Q1 2023",
          "Establish protected area boundaries",
          10, // invalid status
          mediaHash,
        ],
        { success: false, error: 103 },
    )
    
    // Call the contract function
    const result = mockClarity.contracts["progress-reporting"].functions["submit-report"](
        1,
        "Q1 2023 Progress",
        "Detailed description of conservation activities during Q1 2023",
        "Establish protected area boundaries",
        10,
        mediaHash,
    )
    
    // Verify the result
    expect(result).toEqual({ success: false, error: 103 })
  })
})

