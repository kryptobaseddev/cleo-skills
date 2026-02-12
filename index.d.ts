export interface SkillReference {
  name: string;
  description: string;
  path: string;
  references: string[];
  metadata: Record<string, unknown>;
}

export interface ManifestSkill {
  name: string;
  version: string;
  description: string;
  path: string;
  tags: string[];
  status: string;
  tier: number;
  token_budget: number;
  references: string[];
  capabilities: {
    inputs: string[];
    outputs: string[];
    dependencies: string[];
    dispatch_triggers: string[];
    compatible_subagent_types: string[];
    chains_to: string[];
    dispatch_keywords: {
      primary: string[];
      secondary: string[];
    };
  };
  constraints: {
    max_context_tokens: number;
    requires_session: boolean;
    requires_epic: boolean;
  };
}

export interface DispatchMatrix {
  by_task_type: Record<string, string>;
  by_keyword: Record<string, string>;
  by_protocol: Record<string, string>;
}

export interface Manifest {
  $schema: string;
  _meta: Record<string, unknown>;
  dispatch_matrix: DispatchMatrix;
  skills: ManifestSkill[];
}

/** All skill entries from skills.json */
export declare const skills: SkillReference[];

/** Parsed manifest.json dispatch registry */
export declare const manifest: Manifest;

/** Parsed _shared/placeholders.json */
export declare const shared: Record<string, unknown>;

/** List all skill names */
export declare function listSkills(): string[];

/** Get skill metadata from skills.json by name */
export declare function getSkill(name: string): SkillReference | undefined;

/** Resolve absolute path to a skill's SKILL.md file */
export declare function getSkillPath(name: string): string;

/** Resolve absolute path to a skill's directory */
export declare function getSkillDir(name: string): string;

/** Get the dispatch matrix from manifest.json */
export declare function getDispatchMatrix(): DispatchMatrix;

/** Read a skill's SKILL.md content as a string */
export declare function readSkillContent(name: string): string;
